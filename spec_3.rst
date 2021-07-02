.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_3.html

3/Flux Message Protocol
=======================

This specification describes the format of Flux message broker
messages, Version 1.

The Flux message protocol is encapsulated in the
`ZeroMQ Message Transfer Protocol (ZMTP) <http://rfc.zeromq.org/spec:23/ZMTP>`__.

-  Name: github.com/flux-framework/rfc/spec_3.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: draft


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Goals
-----

The Flux message protocol v1 provides a way for Flux utilities and services to
communicate with one another within the context of a job. It has
the following specific goals:

-  Endpoint-count scalability (e.g. to 100K nodes) through multi-hop
   overlay networks.

-  Overlay networks sharable by multiple Flux services and utilities.

-  Provide request-response (RPC) communication idiom.

-  Provide publish-subscribe communication idiom.

-  Handle common failure cases such as hard-hung brokers or crashed nodes,
   but OK to propagate errors to services when necessary to keep running.

-  Peer network transit latency of O(10\ :sup:`-3`\ sec) for small messages

-  Protect messages with strong crypto: privacy, integrity.

-  Fast codec, minimizing heap memory allocations


Background
----------

``flux-broker`` is a message broker daemon for the Flux resource manager
framework. A Flux *instance* is a set of interconnected ``flux-broker`` tasks
that together provide a shared communications substrate for distributed
resource manager services within a job. Services and utilities communicate
by passing messages through the session brokers. There are four
types of messages: events, requests, responses, and keepalives, which
share a common structure described herein.

Event messages are published such that they are available to subscribers
throughout the instance. Events are published with a *topic string*
attached. Subscribers register a list of topic string prefixes
to filter the set of messages they receive.

Requests are messages addressed to a resource manager or broker service.
A topic string identifies the service and *method*. A *nodeid* optionally
identifies a particular ``flux-broker`` rank. Requests follow the ZeroMQ
DEALER-ROUTER message flow, which builds a source-address route at each hop.

Responses are optional replies to requests. They follow the ZeroMQ
ROUTER-DEALER message flow, which unwinds the source address route
accumulated by the request, and uses them to select among peers at each hop.

Keepalives are control messages used by one peer to indicate to another
peer that it is still alive when it is not otherwise communicating.


Implementation
--------------


Rank Assignment
~~~~~~~~~~~~~~~

A *node* is defined as a ``flux-broker`` task. Each node in a Flux
instance of size N SHALL be assigned a rank in the range of 0 to N - 1.
Ranks SHALL be represented by a 32 bit unsigned integer, with the highest
value of (2:sup:`32` - 3).

The rank FLUX_NODEID_ANY (2:sup:`32` - 1) SHALL be reserved to indicate
*any rank* in addressing.

The rank FLUX_NODEID_UPSTREAM (2:sup:`32` - 2) SHALL be reserved to indicate
*any rank* that is upstream of the sender in request addressing.
This value is reserved for the convenience of API implementations
and SHALL NOT appear in the nodeid slot of an encoded message.

A node’s rank SHALL be assigned at broker startup and SHALL NOT change
for the node’s lifetime.

The size of the Flux instance SHALL be determined at startup and SHALL
not change for the life of the Flux instance. [Dynamic resize will
be covered in a future version of this specification.]


Overlay Networks
~~~~~~~~~~~~~~~~

The nodes of a Flux instance SHALL at minimum be interconnected in
tree based overlay network with rank 0 at the root of the tree.

The nodes of a Flux instance MAY be interconnected in additional
overlay networks to improve efficiency or fault tolerance.


Service Addressing
~~~~~~~~~~~~~~~~~~

A Flux service SHALL be identified in a request by a *topic string*,
a set of words delimited by periods, in which the first word identifies
the service, and remaining words represent *methods* within that service.
For example, "kvs.get" refers to the *get* method of the *kvs* service.


Default Request Routing
~~~~~~~~~~~~~~~~~~~~~~~

Request messages MAY be addressed to *any rank* (FLUX_NODEID_ANY).
Such messages SHALL be routed to the local broker, then to the
first match in the following sequence:

1. If topic string begins with a word matching a local broker module
   and the sender is not the same module attached to the same rank
   broker, the message SHALL be routed to the broker module.

2. If the broker is not the root node of the tree based overlay network,
   the message SHALL be routed to a parent node in the tree based overlay
   network, which SHALL re-apply this routing algorithm.

If the message is received by a broker module, but the remaining words of the
topic string do not match a method it implements, the module SHALL
respond with error number 38, "Function not implemented", unless suppressed
as described below.

If the message reaches the root node, but none of the above conditions
are met, the root broker SHALL respond with error number 38,
"Function not implemented", unless suppressed as described below.

A service may send a request *upstream* on the tree based overlay network
by placing the sending nodeid in the message and setting the
FLUX_MSGFLAG_UPSTREAM (16) flag. Such a message SHALL handled
by the broker as if it were addressed to FLUX_NODEID_ANY, except
that the message SHALL NOT be delivered on the sending node.


Rank Request Routing
~~~~~~~~~~~~~~~~~~~~

Request messages MAY be addressed to a specific rank.
Such messages SHALL be routed to the target broker rank, then as follows:

1. If topic string begins with a word matching a local broker module,
   the message SHALL be routed to the module.

If the message is received by a broker module, but the remaining words of the
topic string do not match a method it implements, the module SHALL
respond with error number 38, "Function not implemented", unless suppressed
as described below.

If the message reaches the target node, but none of the above conditions
are met, the broker SHALL respond with error number 38,
"Function not implemented", unless suppressed as described below.

If the message cannot be routed to the target node, the broker making
this determination SHALL respond with error number 113, "No route to host",
unless suppressed as described below.


Suppression of Responses
~~~~~~~~~~~~~~~~~~~~~~~~

If a request message includes the FLUX_MSGFLAG_NORESPONSE (4) flag,
the broker or other responding entity SHALL NOT send a response message.


Event Routing
~~~~~~~~~~~~~

Event messages SHALL only be published by the rank 0 broker. Other ranks MAY
cause an event to be sent by first forwarding it to rank 0.


Payload Conventions
~~~~~~~~~~~~~~~~~~~

Request, response, and event messages MAY contain a payload. Payloads MAY
consist of any byte sequence. To maximize interoperability, norms are
established for common payload types:

1. String payloads SHALL include a terminating NULL character.

2. Structured objects are RECOMMENDED to be represented as JSON [#f1]_.

3. JSON payloads SHALL conform to Internet RFC 7159.

4. JSON payloads SHALL be objects, not arrays or bare values.

5. JSON payloads SHALL include a terminating NULL character.


General Message Format
~~~~~~~~~~~~~~~~~~~~~~

Flux messages are multi-part ZeroMQ messages.

Flux messages MUST include a PROTO message part, positioned last for fast
access. The PROTO part includes flags that indicate the presence of
additional message parts.

Flux messages MAY include a stack of message identity parts comprising
a source address route, positioned first for compatibility with ZeroMQ
DEALER-ROUTER sockets. If message identity parts are present, a zero-size
route delimiter frame MUST be present and positioned next.  A message
identity part SHALL consist of a 16 byte UUID.

Flux messages MAY include a topic string part, positioned after route
delimiter, if any. When the topic string part is first, it is compatible
with ZeroMQ PUB-SUB sockets.

Finally, Flux messages MAY include a payload part, positioned before
the PROTO part. Payloads MAY consist of any byte sequence.

Flux messages are specified in terms of ZeroMQ messages by the following
ABNF grammar [#f2]_

::

   message       = C:request *S:response
                   / S:event
                   / C:keepalive

   ; Multi-part ZeroMQ messages
   C:request       = [routing] topic [payload] PROTO
   S:response      = [routing] topic [payload] PROTO
   S:event         = [routing] topic [payload] PROTO
   C:keepalive     = PROTO

   ; Route frame stack, ZeroMQ DEALER-ROUTER format
   routing         = *identity delimiter
   identity        = 16OCTET       ; socket identity ZeroMQ frame
   delimiter       = 0OCTET        ; empty delimiter ZeroMQ frame

   ; Topic string frame, ZeroMQ PUB-SUB format
   topic           = 1*(ALPHA / DIGIT / ".")

   ; Payload frame
   payload         = *OCTET        ; payload ZeroMQ frame

   ; Protocol frame
   PROTO           = request / response / event / keepalive

   request         = magic version %x01 flags userid rolemask nodeid   matchtag
   response        = magic version %x02 flags userid rolemask errnum   matchtag
   event           = magic version %x04 flags userid rolemask sequence unused
   keepalive       = magic version %x08 flags userid rolemask errnum   status

   ; Constants
   magic           = %x8E          ; magic cookie
   version         = %x01          ; Flux message version

   ; Flags: a bitmask of flag- values below
   flags           = OCTET
   flag-topic      = %x01          ; message has topic string frame
   flag-payload    = %x02          ; message has payload frame
   flag-noresponse = %x04          ; request message should receive no response
   flag-route      = %x08          ; message has route delimiter frame
   flag-upstream   = %x10          ; request should be routed upstream
                                   ;   of nodeid sender
   flag-private    = %x20          ; event message is requested to be
                                   ;   private to sender, instance owner
   flag-streaming  = %x40          ; request/response is part of streaming RPC

   ; Userid assigned by connector at message ingress
   userid          = 4OCTET / userid-unknown
   userid-unknown  = 0xFF.FF.FF.FF

   ; Role bitmask assigned by connector at message ingress
   rolemask        = 4OCTET

   ; Matchtag to correlate request/response
   matchtag        = 4OCTET / matchtag-none
   matchtag-none   = %x00.00.00.00

   ; Target node ID in network byte order
   nodeid          = 4OCTET / nodeid-any
   nodeid-any      = %xFF.FF.FF.FF

   ; UNIX errno in network byte order
   errnum          = 4OCTET

   ; Monotonic sequence number in network byte order
   sequence        = 4OCTET

   ; unused 4-byte field
   unused          = %x00.00.00.00

.. [#f1] `RFC 7159: The JavaScript Object Notation (JSON) Data Interchange Format <http://www.rfc-editor.org/rfc/rfc7159.txt>`__, T. Bray, Google, Inc, March 2014.

.. [#f2] For convenience: the ``C:request``, ``S:response``, ``S:event``, and ``C:keepalive`` ABNF non-terminals refer to ZeroMQ messages, sent by client or server, and built from ordered ZeroMQ message parts (frames). Other non-terminals are built from concatenated ABNF terminals per usual. Thus it is meaningful for ``delimiter``, a message frame, to have zero length, since a zero-length message frame is valid ZMTP.
