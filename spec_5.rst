.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_5.html

5/Flux Broker Modules
=====================

This specification describes the broker extension modules
used to implement Flux services.

-  Name: github.com/flux-framework/rfc/spec_5.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`3/Flux Message Protocol <spec_3>`


Background
----------

Flux services are implemented as dynamically loaded broker plugins called
"broker modules". They are "actors" in the sense that they have
their own thread of control, and interact with the broker and the rest
of Flux exclusively via messages.

The ``flux-module`` front-end utility loads, unloads, and lists broker modules
by exchanging RPC messages with a module management component of the broker.

A broker module exports a function named ``mod_main()`` that is the starting
point for a new broker thread.  The function accepts a ``flux_t`` handle and
an *argc, argv* style argument list.  The ``flux_t`` handle provides direct
communication with the broker over shared memory.  The argument list is derived
from the free arguments on the ``flux module load`` command line.  When
``mod_main()`` returns, the thread is terminated and the module is unloaded.

Prior to calling the function entry point, the broker registers the module
name as a service and arranges for request messages with topics matching the
service to be routed to the module, as described in RFC 3.  Importantly,
messages may be sent to this service immediately upon completion of the
``flux module load`` command.  Handlers for a few standard methods such as
"ping" and "shutdown" are automatically registered for the module.  These
handlers may be overridden by the module if desired.

The broker module implementing a new service is expected to register
message handlers for its methods, then run the flux reactor. It should
use event driven (reactive) programming techniques to remain responsive
while juggling work from multiple clients.

Status messages are sent to the broker via pre-registered reactor
watchers to indicate when the module is initializing, running, finalizing,
or exited. At initialization, a module MAY also manually send a status
message to indicate to the broker when initialization is complete. This
provides synchronization to the broker module loader as well as useful
runtime debug information that can be reported by ``flux module list``.


Implementation
--------------


Well known Symbols
~~~~~~~~~~~~~~~~~~

A broker module SHALL export the following global symbol:

``int mod_main (flux_t *h, int argc, char **argv);``
   A C function that SHALL serve as the entry point for a thread of control.
   This function SHALL return zero to indicate success or -1 to indicate
   failure.  The POSIX ``errno`` thread-specific variable SHOULD be set to
   indicate the type of error on failure.


Status Messages
~~~~~~~~~~~~~~~

A broker module SHALL be considered to be in one of the following states,
represented by the integer values shown in parenthesis:

-  FLUX_MODSTATE_INIT (0) - initializing
-  FLUX_MODSTATE_RUNNING (1) - running
-  FLUX_MODSTATE_FINALIZING (2) - finalizing
-  FLUX_MODSTATE_EXITED (3) - ``mod_main()`` exited

Upon loading the module, the broker SHALL initialize the broker state
to ``FLUX_MODSTATE_INIT``.

After initialization is complete, a module SHALL send an RPC to the
``broker.module-status`` service with the FLUX_RPC_NORESPONSE flag to
notify the broker that the module has started successfully.  In order to
ensure this happens for all modules, the RPC SHALL be sent via a
pre-registered reactor watcher upon a module's first entry to the reactor
if the module has not already sent the message.

Example payload:

.. code:: json

   {
       "status":1
   }

After exiting the reactor and before exiting the module thread, the module
SHALL send an RPC to ``broker.module-status`` indicating that it intends to
exit.  The module SHALL wait for a response to this message before exiting
``mod_main()``.

Example payload:

.. code:: json

   {
       "status":2
   }

Finally once ``mod_main()`` has exited, the module thread SHALL send an RPC
to ```broker.module-status`` with the FLUX_RPC_NORESPONSE flag including
the error status of the module:  zero if ``mod_main()`` exited with a return
code greater than or equal to zero, otherwise the value of ``errno``.

.. code:: json

   {
       "status":2,
       "errnum":0
   }


Load Sequence
~~~~~~~~~~~~~

The broker module loader SHALL launch the module’s ``mod_main()`` in a
new thread. The ``broker.insmod`` response is deferred until the module
state transitions out of FLUX_MODSTATE_INIT. If it transitions immediately to
FLUX_MODSTATE_EXITED, and the ``errnum`` value is nonzero, an error response
SHALL be returned as described in RFC 3.


Unload Sequence
~~~~~~~~~~~~~~~

The broker module loader SHALL send a ``<service>.shutdown`` request to the
module when the module loader receives a ``broker.rmmod`` request for the
module.  In response, the broker module SHALL exit ``mod_main()``, sending
state transition messages as described above, and exit the module’s thread
or process. The final state transition indicates to the broker that it MAY
clean up the module thread.


Built-in Request Handlers
~~~~~~~~~~~~~~~~~~~~~~~~~

All broker modules receive default handlers for the following methods:

``<service>.shutdown``
   The default handler immediately stops the reactor. This handler may
   be overridden if a broker module requires a more complex shutdown sequence.

``<service>.stats-get``
   The default handler returns a JSON object containing message counts.
   This handler may be overridden if module-specific stats are available.
   The ``flux-module stats`` command sends this request and reports the result.

``<service>.stats-clear``
   The default handler zeroes message counts.
   This handler may be overridden if module-specific stats are available.
   The ``flux-module stats --clear`` sends this request.

``<service>.rusage``
   The default handler reports the result of ``getrusage(RUSAGE_THREAD)``.
   The ``flux-module rusage`` sends this request and reports the result.

``<service>.ping``
   The default handler responds to the ping request.
   The ``flux-ping`` command performs ping RPCs.

``<service>.debug``
   The default handler manipulates the value of an integer stored in the
   module’s broker handle aux hash, under the key "flux::debug_flags".
   The ``flux-module debug`` sends this request.


Built-in Event Handlers
~~~~~~~~~~~~~~~~~~~~~~~

In addition, all broker modules subscribe to and register a handler for
the following pub/sub events:

``<service>.stats-clear``
   The default handler zeroes message counts. A custom handler may be
   registered for this event if module-specific stats are available.
   The ``flux-module stats --clear-all`` publishes this event.

Module Attributes
~~~~~~~~~~~~~~~~~

The following key-value pairs SHALL be provided to broker modules via the
``flux_t`` handle AUX container:

flux::uuid
   The UUID assigned to the module which is used for message routing,
   in string form.

flux::name
   The module name.  This is usually derived from basename of the module's
   shared object file, minus the ``.so`` extension.  However it may also be
   overridden by request at module load time.

Multiple Loading
~~~~~~~~~~~~~~~~

A properly conditioned broker module MAY be loaded more than once under
different names.  The following constraints SHOULD be considered:

- The service registered on behalf of the module is based on its name,
  therefore any message handlers for the module's default service MUST
  be registered with a matching topic string.  This may be accomplished
  by using the ``flux::name`` attribute to build matching topic strings,
  or using topic string wildcards.

- There are no safeguards against loading improperly conditioned modules
  multiple times.  A module MAY prevent multiple loading by checking for
  an expected value of ``flux::name``.

Service-specific constraints SHOULD be considered as well.
