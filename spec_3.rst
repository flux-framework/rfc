.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_3.html

3/Flux Message Protocol
#######################

This specification describes the format of Flux message broker
messages, Version 1.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_3.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - draft

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_6`
- :doc:`spec_12`
- `ZeroMQ Message Transfer Protocol (ZMTP) <https://rfc.zeromq.org/spec:23/ZMTP>`_

Goals
*****

The Flux message protocol v1 provides a way for Flux utilities and services to
communicate with one another within the context of a flux instance. It has
the following specific goals:

-  Enable Flux components to communicate within a Flux instance.

-  Enable the remote procedure call communication idiom.

-  Enable the publish-subscribe communication idiom.

-  Allow Flux services to be deployed and accessed without consulting a
   location service.

-  Avoid sending Flux data over networks without encryption.

-  Allow messages to be propagated over different transports including, but
   not limited to, ZeroMQ.

-  Enable scalability to many thousands of nodes.

-  Implement failure mitigation strategies that are simple to reason about.

-  Ensure that messages between any pair of endpoints are received in
   transmission order.

Background
**********

The ``flux-broker`` is a message broker daemon for the Flux resource manager
framework.  A Flux *instance* is a set of ``flux-broker`` processes that
form an overlay network for distributed communication.  Flux components
communicate with each other by exchanging messages over the overlay network.

In a Flux instance of size *N*, each broker is assigned a rank from 0 to
*N - 1*.  The overlay network is a tree topology, with the root of the tree
at rank 0.  Different tree shapes are permitted as long as peer connections are
only between tree levels, and each node has at most one parent.  The tree
shape, the instance size, and each broker's rank are fixed once the instance
begins running.

.. figure:: images/tree.png
   :width: 150
   :alt: Flux overlay network topology
   :align: center

   The Flux overlay network with root broker at rank 0.

The overlay network is capable of routing messages using several methods.
Messages may be routed over the shortest path between any two brokers, using
"smart host" routing where messages are forwarded upstream until a more
informed broker knows how to route it, or by multi-casting to all broker
ranks.  These capabilities support remote procedure call (RPC) and
publish-subscribe, the two main communication idioms used in Flux.

If a broker fails or its connection is lost, any pending RPCs involving that
broker as a target or as a message router receive automatic error responses,
and the broker is forced to restart before reconnecting.  If the failed broker
is an interior node of the tree acting as a router, its entire sub-tree is
forced to restart.  In a Flux system instance, this restart is managed by
systemd.

Flux messages share a common structure that is strongly influenced by ZeroMQ
conventions, since ZeroMQ provides a transport for Flux messages, and certain
ZeroMQ socket types impose structural requirements on messages for routing
and subscription filtering.  Flux messages may be sent over other transports,
however.  For example, regular UNIX domain stream sockets transport messages
between local processes and Flux brokers.

There are four distinct Flux message types:  *request* and *response* messages
for remote procedure call;  *event* messages for publish-subscribe, and
*control* messages for internal use by the overlay network implementation.

Implementation
**************

Common Message Format
=====================

All Flux messages share a common message structure that is compatible with
the ZeroMQ message transport:

- Message SHALL be divided into ordered *parts*.

- Messages SHALL support a *route stack* of message parts for source-address
  routing.

- Messages SHALL support a *topic string* message part for subscriber
  filtering.

The boundary between message parts SHALL be preserved by message transports;
that is, Flux messages sent as an array of parts MUST be received as an array
of parts, not a concatenated blob.

Message transports MAY modify Flux messages if directed to do so.  For
example, a ZeroMQ ROUTER socket implements source-address routing by adding
a message part in one direction and removing one in the opposite direction.

Optional Message Parts
----------------------

The following message parts MAY appear in Flux messages, in the following
order:

routes
  Messages MAY contain a *route stack* for request/response message routing.
  Each route SHALL be a message part containing a NULL-terminated UUID string
  that represents one route hop.  The most recent hop SHALL be on the top of
  the stack.

route stack delimiter
  The route stack delimiter is an empty message frame that delimits the route
  stack from other message parts.  The delimiter is REQUIRED if the message
  contains any routes.  The routes and delimiter MUST be the first message
  parts in the message, if present.

topic string
  Messages MAY contain a NULL-terminated string representing an event topic
  or a RPC service endpoint.

payload
  Messages MAY contain a payload of zero or more bytes of user-specific
  content.

Required Message Parts
----------------------

Flux messages are REQUIRED to have one message part that acts as a protocol
header and is encoded as described by the following ABNF [#f2]_ grammar.
This block of data MUST be the last message part in the message.  Note the
following about the message header:

- It has a fixed length.

- It includes the message type.

- The 4-byte integers SHALL be encoded in network (big endian) byte order.

- Some fields (notably the last two 4-byte integers) have different meanings
  depending on the message type.

- The message flags determine which of the optional message parts are present.

- The message credentials (*userid* and *rolemask*) are those of the user that
  sent the message, and are set when the message is accepted by a broker.

.. code-block:: ABNF

   PROTO           = request / response / event / control

   request         = magic version %x01 flags userid rolemask nodeid   matchtag
   response        = magic version %x02 flags userid rolemask errnum   matchtag
   event           = magic version %x04 flags userid rolemask sequence unused
   control         = magic version %x08 flags userid rolemask type     status

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

   ; Target node ID
   nodeid          = 4OCTET / nodeid-any
   nodeid-any      = %xFF.FF.FF.FF

   ; UNIX errno
   errnum          = 4OCTET

   ; Monotonic sequence number
   sequence        = 4OCTET

   ; Control message type
   type            = 4OCTET

   ; Control message status
   status          = 4OCTET

   ; unused 4-byte field
   unused          = %x00.00.00.00

Request Message Type
====================

When the message header indicates a message type of *request* (1),
the following rules apply:

- The message SHALL include a route delimiter.

- The message MAY include routes.  One SHALL be added by the system each time
  the request transits a socket.

- The message SHALL include a topic string, which MAY include period
  delimiters.  The first portion (up to the first period) SHALL be interpreted
  as a service name.

- The message MAY include a payload.

- The header MAY include the *upstream* flag, which affects request routing.

- The header SHALL include a *nodeid* field which affects request routing.

- The header SHALL include a *matchtag* field, used to match requests and
  responses.

- If the header *noresponse* flag is set, responses to the request SHALL
  be suppressed.

Request Routing
---------------

Request messages received by a broker are routed in three ways, depending on
the value of the *nodeid* header field and the *upstream* header flag:

1. If the request *nodeid* is set to the *nodeid-any* constant, the broker
SHALL attempt to match a locally-registered service with the request topic
string.  On a match, the message SHALL be routed to that service.  Otherwise,
it SHALL be routed to the next upstream broker peer, which does the same.
If the message reaches the root broker without matching a service, that
broker SHALL generate a response message containing POSIX error number 39
(Function not implemented).

2. If the request *nodeid* is not *nodeid-any* and the *upstream* flag is
clear, the nodeid SHALL be interpreted as the destination broker rank.
Brokers SHALL use topology data to route these requests to the destination
broker.  Upon receipt, the destination broker SHALL attempt to match a
locally-registered service with the request topic string.  On a match, the
message SHALL be routed to that service.  Otherwise, the broker SHALL generate
a response message containing POSIX error number 39 (Function not
implemented).

3. If the request *nodeid* is not *nodeid-any* and the *upstream* flag is set,
the nodeid SHALL be interpreted as the broker rank of the sender.  The
receiving broker SHALL NOT attempt to match a locally-registered service on
that rank.  Instead, the message SHALL be routed to the upstream broker peer,
as in the first case, until a service is matched or an error is generated.

.. note::
  The *upstream* flag enables a distributed service that registers the same
  service name on all broker ranks to send requests to its own service on an
  upstream broker.  Without the flag, the request would be looped back to the
  sender.  The same could be accomplished by addressing the request to the
  upstream broker's rank, but that requires knowledge of the topology, which
  is a little more involved than setting a message flag.

Response Message Type
=====================

When the message header indicates a message type of *response* (2),
the following rules apply:

- The message SHALL include a route delimiter and routes copied from the
  request.  A route SHALL be removed by the system each time the response
  transits a socket.  The route selects the next peer hop.

- The message SHALL include a topic string, copied from the request.

- The message MAY include a payload.

- The header SHALL include a *errnum* field.

- The header SHALL include a *matchtag* field, copied from the request.

.. figure:: images/messages.png
   :width: 600
   :alt: Flux message examples
   :align: center

   Example of (a) Flux request message, and (b) Flux response message.  Integer
   values are in hex.

Event Message Type
==================

When the message header indicates a message type of *event* (4),
the following rules apply:

- The message SHALL NOT include routes or a route delimiter.

- The message SHALL include a topic string.

- The message MAY include a payload.

- The header SHALL include a monotonically increasing event sequence number.

- The header MAY include the *private* flag, which instructs the broker only
  to deliver the event to connections with credentials matching the event
  sender or the instance owner.

Event messages SHALL only be published by the rank 0 broker. Other ranks MAY
cause an event to be sent by first forwarding it to rank 0.

Control message type
====================

When the message header indicates a message type of *control* (8),
the following rules apply:

- The message SHALL NOT include routes or a route delimiter.

- The message SHALL NOT include a topic string.

- The message SHALL NOT include a payload.

- The header SHALL include two general purpose 4-byte integers labeled
  *type* and *status*.

- The message SHALL NOT be routed - it is only for use between direct peers.

.. note::
  Control messages are currently used between overlay network peers to
  communicate status, send heartbeats, and to force disconnects.  They are
  also used between broker modules and the broker module loader to communicate
  module status.  Since they are not routed, they are not of much use outside
  of those contexts.

Payload Conventions
===================

Request, response, and event messages MAY contain a payload. Payloads MAY
consist of any byte sequence. To maximize interoperability, norms are
established for common payload types:

1. String payloads SHALL include a terminating NULL character.

2. Structured objects are RECOMMENDED to be represented as JSON [#f1]_.

3. JSON payloads SHALL conform to Internet RFC 7159.

4. JSON payloads SHALL be objects, not arrays or bare values.

5. JSON payloads SHALL include a terminating NULL character.

Message Framing and Security
============================

When Flux uses ZeroMQ for transport (overlay network peer connections and the
``shmem`` connector), ZeroMQ handles security and message framing.  When Flux
uses a UNIX domain stream socket for transport (``local`` connector), Flux
handles security and message framing as described below.  The remainder of
this section applies only to connection over UNIX domain stream sockets.

Upon accepting a connection from a new client, Flux SHALL determine the peer
identity using SO_PEERCRED and apply security policies described in RFC 12 to
determine if user is authorized to access Flux.  If the user is *denied*
access, a single nonzero byte representing a POSIX errno SHALL be sent to the
client.  When the client receives a nonzero errno byte, it SHOULD interpret
the error and disconnect.  If the user is *allowed* access, a single zero byte
SHALL be sent to the client.  Upon receipt of the zero byte, the client MAY
proceed to exchange Flux messages on the socket.

Messages SHALL be framed as follows:  First, within a message, message parts
SHALL be encoded as a *size* field followed by a *data* field.  The *size*
field consists of a short message size (1 byte) followed by an optional long
message size (4 bytes).  The message sizes SHALL be interpreted as unsigned
integers in network byte order.

short message parts
  If the *data* field is from 0 to 254 bytes, its length SHALL be placed
  in the short message size.  The long message size SHALL be omitted.

long message parts
  If the *data* field is 255 bytes or greater, its length SHALL be placed in
  the long message size.  The short message size SHALL be set to a value of 255.

After the message parts are encoded and concatenated, the message SHALL be
prefaced with a 4 byte magic value of (``FF``, ``EE``, ``00``, ``12``) and
a 4-byte unsigned integer message length in network byte order.  The message
length SHALL be set to the size of the concatenated message parts, including
their length fields.

.. figure:: images/messages_framed.png
   :width: 200
   :alt: Flux message examples (framed)
   :align: center

   Example of a Flux request message with framing for transmission over a
   UNIX domain stream socket.

References
**********

.. [#f1] `RFC 7159: The JavaScript Object Notation (JSON) Data Interchange Format <https://www.rfc-editor.org/rfc/rfc7159.txt>`__, T. Bray, Google, Inc, March 2014.

.. [#f2] For convenience: the ``C:request``, ``S:response``, ``S:event``, and ``C:control`` ABNF non-terminals refer to multi-part messages, sent by client (C) or server (S). Message part *size* framing is not shown for clarity.
