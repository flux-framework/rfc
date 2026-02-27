.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_5.html

5/Flux Broker Modules
#####################

.. highlight:: c

.. default-domain:: c

This specification describes the broker extension modules
used to implement Flux services.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_5.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_3`
- :doc:`spec_6`

Goals
*****

Flux broker modules allow Flux to be extended with new services.
The broker module design has the following goals:

- A module should execute in its own thread/process, with its own event loop.

- A module communicates only with messages.

- A module may act as a Flux RPC client and/or server.

- A module may subscribe to event messages.

- A module may implement a distributed service or a centralized one.

- A single module may be loaded more than once under different names.

- A module may be loaded by the broker as a dynamic shared object, or
  launched as a standalone process.

- A module may be packaged and distributed independently of flux-core.

Implementation
**************

A broker module SHALL be structured as a dynamic shared object or
a standalone process.

Dynamic Shared Object
=====================

A broker module MAY be implemented as a dynamic shared object (DSO).
The DSO MAY be loaded directly by the broker or by an independent process
acting as its proxy, depending on configuration.

The DSO SHALL implement the following function and export its symbol:

.. function:: int mod_main (flux_t *h, int argc, char **argv)

  :var:`h`
    The broker handle used for sending and receiving messages

  :var:`argc`, :var:`argv`
    The module arguments, if any.  Unlike the C convention, the first
    element is the first argument.

This function is the entry point for the module's thread of control.
Normally it would enter the Flux reactor and execute until notified
that it is being shutdown via a service shutdown message (see below).

This function SHALL return zero to indicate success or -1 to indicate
failure.  The POSIX :var:`errno` thread-specific variable SHOULD be set to
indicate the type of error on failure.

.. note::

  When :func:`mod_main` exits with an error code before the module state
  has been reported as FLUX_MODSTATE_RUNNING (see below), the module load
  request fails.  Once it has entered the RUNNING state, the default response
  to a failed module in a non-system instance is to post a panic event to
  the broker and shut down the TBON subtree (or the whole instance if this
  occurs on the leader rank).  The system instance, on the other hand,
  logs the failure and continues to run.

Standalone Process
==================

A broker module MAY be implemented as a standalone process.
The process is expected to be a loader for a particular type of module
environment.

Currently only one loader is supported, for loading module DSOs that
conform to the previous section:

.. code-block:: console

  flux-module-exec MODULE

The MODULE argument is the DSO path or name.

The following environment variables SHALL be passed to the loader:

FLUX_MODULE_URI

  The URI that SHALL be opened for a dedicated Flux message channel
  to this module, for example ``fd://42``.

FLUX_MODULE_PATH

  The colon-separated list of directories that SHOULD be searched for MODULE
  if it is not fully-qualified.

In the future, other loaders MAY be supported to enable broker modules
to be written in languages such as Python that would be inconvenient to
use to build conformant DSOs.

Module Name
===========

Each loaded module SHALL have a unique name.

If unspecified, the module name MAY be derived from the path name used to
load it.

The module name SHALL be registered as a default service provided by the
module.  This means that request messages with topic strings that begin
with ``NAME.`` are routed to the module for handling.  For example,
``kvs.lookup`` is routed to the ``kvs`` module.  Additional services
MAY be dynamically registered by the module.

The module MAY discover its own name via the ``flux::name`` :type:`flux_t`
aux key.

.. note::

  The capability to load modules under different names is relatively new.
  Proper functioning requires that a module not hard code topic strings when
  registering message handlers.  Legacy modules may prevent confusion by
  checking the value of ``flux::name`` and treating an unexpected value as
  a fatal error.

Module UUID
===========

Each loaded module SHALL be assigned a UUID.

The UUID is used for message routing as described in :doc:`spec_6`.

The module MAY discover its own uuid via the ``flux::uuid`` :type:`flux_t`
aux key.

Welcome Request
===============

The broker SHALL send a request message with topic string ``welcome``
to each module at startup.  The request payload SHALL consist of a JSON
object with the following keys:

.. object:: welcome request

  .. object:: args

    (*array*, REQUIRED) A list of module arguments, each of which SHALL
    be of type :type:`string`.

  .. object:: attrs

    (*object*, REQUIRED) A dictionary of cacheable broker attributes.  The
    values SHALL be of type :type:`string`.

  .. object:: conf

    (*object*, REQUIRED) The initial Flux instance configuration object.

  .. object:: name

    (*string*, REQUIRED) The module name.

  .. object:: uuid

    (*string*, REQUIRED) The module uuid.

The module MUST NOT send a response message to the welcome request.

For DSOs, the module loader handles the welcome message before :func:`mod_main`
is called.  When DSOs are loaded directly into the broker, the welcome
message is handled internally in the new module thread.

Status Request
==============

A broker module SHALL send a request message with topic string
``module.status`` to the broker when its status changes.  The request
payload SHALL consist of a JSON object with the following keys:

.. object:: module.status request

  .. object:: status

    (*integer*, REQUIRED) The module status, with values:

      FLUX_MODSTATE_INIT (0)
        The initial state.  This value is assumed when a module is created and
        SHALL NOT be reported in a module status message.  This value SHOULD
        be reported with FLUX_MSGFLAG_NORESPONSE.

      FLUX_MODSTATE_RUNNING (1)
        The module is running.  The module SHALL report this status when its
        initialization has completed successfully.  This value SHOULD be
	reported with FLUX_MSGFLAG_NORESPONSE.

      FLUX_MODSTATE_FINALIZING (2)
        The module is shutting down.  This module MAY report this status
        during shutdown to request that the broker stop sending requests to
        the module and automatically respond to them with ENOSYS.

      FLUX_MODSTATE_EXITED (3)
        The module is no longer executing, e.g. :func:`mod_main` has exited.
        This value SHOULD be reported with FLUX_MSGFLAG_NORESPONSE.

    (*errnum*, OPTIONAL) A non-zero value with FLUX_MODSTATE_EXITED SHALL
    indicate that the module has failed, and MAY be interpreted as a
    POSIX :var:`errno` value.  If not present, a value of zero is
    assumed.

Unless FLUX_MSGFLAG_NORESPONSE is set on the request, the broker SHALL
respond with an empty payload on success or an appropriate error on failure.

Module status requests are usually sent by the module loader.
For example, FLUX_MODSTATE_FINALIZING and FLUX_MODSTATE_EXITED are reported
by the loader after :func:`mod_main` returns, and FLUX_MODSTATE_RUNNING
is automatically reported by a loader-installed watcher when the
module enters its reactor.

FLUX_MODSTATE_FINALIZING is optionally used by the module loader to implement
a synchronous handshake to drain the message channel of pending requests after
:func:`mod_main` returns:

1. :func:`mod_main` returns.
2. The module loader reports FLUX_MODSTATE_FINALIZING and waits for the
   response.
3. On receipt of FLUX_MODSTATE_FINALIZING, the broker sets a flag on the
   module so that future requests to the module are automatically sent
   ENOSYS responses.  It then responds to the status request.
4. The module loader responds with ENOSYS to any requests in the module's
   message channel.
5. The module message channel is destroyed.

Shutdown Request
================

The broker SHALL send a shutdown request to a module when it is to be unloaded.

.. object:: NAME.shutdown request

There is no payload.  The module SHALL respond by terminating, e.g.
returning from :func:`mod_main`.

The module SHALL NOT respond to this request.

Default Message Handlers
========================

Module loaders MAY register default service methods on behalf of modules.
All request payloads are empty.

The default service methods MAY be overridden in a module by registering
a message handler for the same topic string.

.. object:: NAME.shutdown request

   The default handler immediately stops the reactor. This handler MAY
   be overridden if a broker module requires a more complex shutdown sequence.

.. object:: NAME.stats-get request

   The default handler returns a JSON object containing message counts.
   This handler MAY be overridden if module-specific stats are available.
   The ``flux-module stats`` command sends this request and reports the result.

.. object:: NAME.stats-clear request

   The default handler zeroes message counts.
   This handler MAY be overridden if module-specific stats are available.
   The ``flux-module stats --clear`` sends this request.

.. object:: NAME.rusage request

   The default handler reports the result of ``getrusage(RUSAGE_THREAD)``.
   The ``flux-module rusage`` sends this request and reports the result.

.. object:: NAME.ping request

   The default handler responds to the ping request.
   The ``flux-ping`` command performs ping RPCs.

.. object:: NAME.debug request

   The default handler manipulates the value of an integer stored in the
   module’s broker handle aux hash, under the key "flux::debug_flags".
   The ``flux-module debug`` sends this request.

In addition, module loaders MAY subscribe to the following event and
provide a default handler.

.. object:: NAME.stats-clear event

   The default handler zeroes message counts. A custom handler MAY be
   registered for this event if module-specific stats are available.
   The ``flux-module stats --clear-all`` publishes this event.


Module Management
=================

The broker SHALL attempt to load a module in response to a load request:

.. object:: module.load request

  .. object:: path

    (*string*, REQUIRED) The module target which MAY be a file path
    or a module name.  If a module name is specified, the broker SHALL look up
    the module file path by name.

  .. object:: name

    (*string*, OPTIONAL) The module name under which the target module
    is loaded.  This overrides the name determined from the module path.

  .. object:: args

    (*array*, REQUIRED) A list of module arguments, each of which SHALL
    be of type :type:`string`.

  .. object:: exec

    (*boolean*, OPTIONAL) A flag indicating that the module DSO should be
    loaded using the standalone process loader.

.. object:: module.load response

   The response payload is empty.  The response SHOULD be delayed until
   the module reports a status, e.g. FLUX_MODSTATE_RUNNING.

The broker SHALL attempt to unload a module in response to a remove request:

.. object:: module.remove request

  .. object:: name

    (*string*, REQUIRED) The module name.

  .. object:: cancel

    (*boolean*, OPTIONAL) A flag indicating that the module should be forcibly
    terminated, e.g. if it did not respond to an exit request earlier.

.. object:: module.remove response

   The response payload is empty.

The broker SHALL provide a list of loaded modules upon in response to a
list request:

.. object:: module.list request

   The request payload is empty

.. object:: module.list response

  .. object:: mods

    (*array*, REQUIRED) A list of module objects.  Each object contains the
    following fields:

    .. object:: name

      (*string*, REQUIRED) The module name.

    .. object:: path

      (*string*, REQUIRED) The module path.

    .. object:: idle

      (*integer*, REQUIRED) The module idle time in seconds.

    .. object:: status

      (*status*, REQUIRED) The module state.

    .. object:: services

      (*array*, REQUIRED) A list of dynamically registered services.

    .. object:: sendqueue

      (*integer*, REQUIRED) The number of sent messages pending in the module
      message channel.

    .. object:: recvqueue

      (*integer*, REQUIRED) The number of received messages pending in the
      module message channel.

The broker SHALL temporarily hold (defer) messages sent by a module in response
to a debug request.  This is sometimes useful in test to simulate a deadlocked
or backlogged module.

.. object:: module.debug request

  .. object:: name

    (*string* REQUIRED) The module name

  .. object:: defer

    (*boolean*, OPTIONAL) If true, message sent by the module are temporarily
    deferred.  If missing or false, deferral is disabled and any deferred
    messages are sent.

.. object:: module.debug response

   The response payload is empty

The broker SHALL provide trace information for messages sent and received
to modules in response to a trace request.

.. object:: module.trace request

  .. object:: names

    (*array*, REQUIRED) A list of module names, which must be of type
    :type:`string`, to trace.

  .. object:: typemask

    (*integer*, REQUIRED) A bitmask of message types to filter messages
    by type.

  .. object:: topic_glob

    (*string*, REQUIRED) A glob pattern to filter messages by topic string.

.. object:: module.trace response

   One response is sent per traced message.  Details are not specified here.
