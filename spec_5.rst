.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_5.html

5/Flux Comms Modules
====================

This specification describes the broker extension modules
used to implement Flux services.

-  Name: github.com/flux-framework/rfc/spec_5.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`3/CMB1 - Flux Comms Message Broker Protocol <spec_3>`


Background
----------

Flux services are implemented as dynamically loaded plugins called
"comms modules". They are "actors" in the sense that they have
their own thread of control, and interact with the broker and the rest
of Flux exclusively via messages.

The ``flux-module`` front-end utility loads, unloads, and lists comms modules
by exchanging RPC messages with a module management component of the broker.

A comms module exports two symbols: a ``mod_main()`` function, and
a ``mod_name`` NULL-terminated string.

The broker starts a comms module by calling its ``mod_main()`` function in
a new thread. The broker provides a broker handle and argv vector
style arguments to the via ``mod_main()`` arguments. The arguments originate
on the ``flux-module load`` command line.

Prior to calling ``mod_main()``, the broker registers a service for the
comms module based on the value of ``mod_name``. Request messages with
topic strings starting with this service name are diverted by the broker
to the comms module as described in RFC 3. The portion of the topic string
following the service name is called a "service method". A comms module
may register many service methods.

The broker also pre-registers handlers for service methods that all comms
modules are expected to provide, such as "ping" and "shutdown". These
handlers may be overridden by the comms module if desired.

The comms module implementing a new service is expected to register
message handlers for its methods, then run the flux reactor. It should
use event driven (reactive) programming techniques to remain responsive
while juggling work from multiple clients.

Keepalive messages are sent by pre-registered reactor watchers to the broker,
to indicate when the comms module is initializing, waiting for reactor events,
busy doing work, finalizing, or exited. This provides synchronization to
the comms module loader, as well as useful runtime debug information that
can be reported by ``flux module list``.


Implementation
--------------


Well known Symbols
~~~~~~~~~~~~~~~~~~

A comms module SHALL export the following global symbols:

``const char \*mod_name;``
   A null-terminated C string defining the module name.

``int mod_main (void \*context, int argc, char \**argv);``
   A C function that SHALL serve as the entry point for a thread of control.
   This function SHALL return zero to indicate success or -1 to indicate failure.
   The POSIX ``errno`` thread-specific variable SHOULD be set to indicate the
   type of error on failure.


Keepalive Values
~~~~~~~~~~~~~~~~

A comms module SHALL send RFC 3 keepalive messages containing status
integers to the broker over its broker handle. Status integers are
enumerated as follows:

-  FLUX_MODSTATE_INIT (0) - initializing

-  FLUX_MODSTATE_SLEEPING (1) - sleeping

-  FLUX_MODSTATE_RUNNING (2) - running

-  FLUX_MODSTATE_FINALIZING (3) - finalizing

-  FLUX_MODSTATE_EXITED (4) - ``mod_main()`` exited

Keepalive messages SHALL be sent to the broker on each state transition.
In addition, keepalive message MAY be sent to the broker at regular
intervals. The keepalive ``errnum`` field SHALL be zero except
when ``mod_main()`` returns a value of -1 indicating failure and state
transitions to FLUX_MODSTATE_EXITED. In this case ``errnum`` SHALL be set
to the value of POSIX ``errno`` set by ``mod_main()`` before returning.

The broker MAY track the number of session heartbeats since an
comms module last sent a message and report this as "idle time"
for the comms module.


Load Sequence
~~~~~~~~~~~~~

The broker module loader SHALL launch the comms module’s ``mod_main()`` in a
new thread. The ``cmb.insmod`` response is deferred until the comms module
state transitions out of FLUX_MODSTATE_INIT. If it transitions immediately to
FLUX_MODSTATE_EXITED, and the ``errnum`` value is nonzero, an error response
SHALL be returned as described in RFC 3.


Unload Sequence
~~~~~~~~~~~~~~~

The broker module loader SHALL send a ``<service>.shutdown`` request to the
comms module when the module loader receives a ``cmb.rmmod`` request for the
module. In response, the comms module SHALL exit ``mod_main()``, send a
keepalive transition to FLUX_MODSTATE_EXITED state, and exit the comms
module’s thread or process. This final state transition indicates to
the broker that it MAY clean up the module thread.


Built-in Request Handlers
~~~~~~~~~~~~~~~~~~~~~~~~~

All comms modules receive default handlers for the following methods:

``<service>.shutdown``
   The default handler immediately stops the reactor. This handler may
   be overridden if a comms module requires a more complex shutdown sequence.

``<service>.stats.get``
   The default handler returns a JSON object containing message counts.
   This handler may be overridden if module-specific stats are available.
   The ``flux-module stats`` command sends this request and reports the result.

``<service>.stats.clear``
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

In addition, all comms modules subscribe to and register a handler for
the following events:

``<service>.stats.clear``
   The default handler zeroes message counts. A custom handler may be
   registered for this event if module-specific stats are available.
   The ``flux-module stats --clear-all`` publishes this event.


Module Management Message Definitions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Module management messages SHALL follow the CMB1 rules described
in RFC 3 for requests and responses with JSON payloads.

The broker comms module loader SHALL implement the ``cmb.insmod``,
``cmb.rmmod``, and ``cmb.lsmod`` methods.

Module management messages are described in detail by the following
ABNF grammar:

::

   MODULE          = C:insmod-req S:insmod-rep
                   / C:rmmod-req  S:rmmod-rep
                   / C:lsmod-req  S:lsmod-rep

   ; Multi-part zeromq messages
   C:insmod-req    = [routing] insmod-topic insmod-json PROTO ; see below for JSON
   S:insmod-rep    = [routing] insmod-topic PROTO

   C:rmmod-req     = [routing] rmmod-topic rmmod-json PROTO   ; see below for JSON
   S:rmmod-rep     = [routing] rmmod-topic PROTO

   C:lsmod-req     = [routing] lsmod-topic PROTO
   S:lsmod-rep     = [routing] lsmod-topic lsmod-json PROTO   ; see below for JSON

   ; topic strings are optional service + module operation
   insmod-topic    = "cmb.insmod"
   rmmod-topic     = "cmb.rmmod"
   lsmod-topic     = "cmb.lsmod"

   ; PROTO and [routing] are as defined in RFC 3.

JSON payloads for the above messages are as follows, described using
`JSON
Content Rules <https://tools.ietf.org/html/draft-newton-json-content-rules-05>`__

::

   insmod-json {
       "path"     : string,          ; path to module file
       "args"     : [ *: string ]    ; argv array (first element is not special)
   }

   rmmod-json {
       "name"     : string,          ; module name
   }

   lsmod-obj {
       "name"     : string           ; module name
       "size"     : integer 0..      ; module file size
       "digest"   : string           ; SHA1 digest of module file
       "idle"     : integer 0..      ; comms idle time in heartbeats
       "status"   : integer 0..      ; module state (enumerated above)
   }

   lsmod-json {
       "mods"     : [ *lsmod-obj ]
   }
