.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_18.html

18/KVS Event Log Format
=======================

This specification describes the format for Flux KVS Event Logs.

-  Name: github.com/flux-framework/rfc/spec_18.rst

-  Editor: Stephen Herbein <sherbein@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`21/Job States and Events <spec_21>`


Background
----------

The initial use case for Flux KVS Event Logs is recording events
that cause Flux job state transitions, for historical and
synchronization purposes. These events are defined in detail
in RFC 21.

KVS atomic append capability enables multiple writers to add events to
a single Flux Event Log in a race-free manner. KVS watch capability
enables a Flux Event Log to be used for synchronization.


Event Log Format
----------------

A Flux KVS Event Log SHALL consist of events separated by newlines.
Each event SHALL be an independent JSON object, serialized without
embedded newlines. The Event Log as a whole is not valid JSON.

An Event Log SHALL only be written by appending one or more whole event
objects. It SHALL NOT be created empty, and it SHALL NOT be rewritten
or truncated. It MAY be removed when it is no longer needed.

The following keys are REQUIRED in an event object:

timestamp
   (number) The time stamp indicating when the event was created,
   represented as seconds since the Unix Epoch (1970-01-01 UTC).
   It MUST be greater than zero, and MAY include sub-second precision.

name
   (string) The name of the event.

The following keys are OPTIONAL in an event object:

context
   (object) Application-specific event data.


Example
-------

An example Flux Event Log:

::

   {"timestamp":1552593348.073045,"name":"submit","context":{"urgency":16,"userid":5588,"flags":0}}
   {"timestamp":1552593547.411336,"name":"urgency","context":{"urgency":0,"userid":5588}}
   {"timestamp":1552593348.088391,"name":"alloc",context:{"note":"rank0/core[0-1]"}}
   {"timestamp":1552593348.093541,"name":"free"}
   {"timestamp":1552593348.089787,"name":"start"}
   {"timestamp":1552593348.092830,"name":"release","context":{"ranks":"all","final":true}}
   {"timestamp":1552593348.090927,"name":"finish","context":{"status":0}}
   {"timestamp":1552593348.104432,"name":"clean"}
