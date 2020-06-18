.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_6.html

6/Flux Remote Procedure Call Protocol
=====================================

This specification describes how Flux Remote Procedure Call (RPC) is
built on top of request and response messages defined in RFC 3.

-  Name: github.com/flux-framework/rfc/spec_6.rst

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


Goals
-----

Flux RPC protocol enables comms modules, utilities, or other software
communicating with a Flux comms session to call the methods implemented
by comms modules. Flux RPC has the following goals:

-  Support location-neutral service addressing, without a location broker.

-  Support a high degree of concurrency in both clients and servers

-  Avoid over-engineered mitigations for timeouts, congestion avoidance, etc.
   that can be a liability in high performance computing environments.

-  Provide a mechanism to abort in-progress RPC calls.


Implementation
--------------

A remote procedure call SHALL consist of one request message
sent from a client to a server, and zero or more response messages sent
from a server to a client. The client and server roles are not
mutually-exclusive—​comms modules often act in both roles.

::

   +--------+    Request      +--------+
   |        | --------------> |        |
   | Client |                 | Server |
   |        | <-------------- |        |
   +--------+    Response     +--------+


Request Message
~~~~~~~~~~~~~~~

Per RFC 3, the request message SHALL include a nodeid and topic string
used to aid the broker in selecting appropriate routes to the server.
The client MAY address the request in a location-neutral manner
by setting nodeid to FLUX_NODEID_ANY, then the tree-based overlay network
will be followed to the root looking for a matching service closest
to the client.

The request message MAY include a service-defined payload.

Requests to services that send multiple responses SHALL set the
FLUX_MSGFLAG_STREAMING message flag.

A request MAY indicate that the response should be suppressed by
setting the FLUX_MSGFLAG_NORESPONSE message flag.


Response Messages
~~~~~~~~~~~~~~~~~

The server SHALL send zero or more responses to each request, as
established by prior agreement between client and server (e.g. defined
in their protocol specification) and determined by message flags.

Responses SHALL contain topic string and matchtag values copied from
the request, to facilitate client response matching.

If the request succeeds and a response is to be sent, the server SHALL
set errnum in the response to zero and MAY include a service-defined payload.

If the request fails and a response is to be sent, the server SHALL set
errnum in the response to a nonzero value conforming to
`POSIX.1 errno encoding <http://man7.org/linux/man-pages/man3/errno.3.html>`__
and MAY include an error string payload. The error string, if included
SHALL consist of a brief, human readable message. It is RECOMMENDED that
the error string be less than 80 characters and not include line
terminators.

The server MAY respond to requests in any order.


Streaming Responses
~~~~~~~~~~~~~~~~~~~

Services that send multiple responses to a request SHALL immediately reject
requests that do not have the FLUX_MSGFLAG_STREAMING flag set by sending
an EPROTO (error number 71) error response.

The response stream SHALL consist of zero or more non-error responses,
terminated by exactly one error response.

The service MAY signify a successful "end of response stream" with an ENODATA
(error number 61) error response.

The FLUX_MSGFLAG_STREAMING flag SHALL be set in all non-error responses in
the response stream. The flag MAY be set in the final error response.


Matchtag Field
~~~~~~~~~~~~~~

RFC 3 provisions request and response messages with a 32-bit matchtag field.
The client MAY assign a unique (to the client) value to this field,
which SHALL be echoed back by the server in responses. The client MAY
use this matchtag value to correlate responses to its concurrently
outstanding requests.

Note that matchtags are only unique to the client. Servers SHALL NOT
use matchtags to track client state unless paired with the client UUID.

The client MAY set matchtag to FLUX_MATCHTAG_NONE (0) if it has no need
to correlate responses in this way, or a response is not expected.

The client SHALL NOT reuse matchtags in a new RPC unless it is certain
that all responses from the original RPC have been received. A matchtag
MAY be reused if a response containing the matchtag arrives with the
FLUX_MSGFLAG_STREAMING message flag clear, or if the response contains
a non-zero error number.


Exceptional Conditions
~~~~~~~~~~~~~~~~~~~~~~

If a request cannot be delivered to the server, the broker MAY respond to
the sender with an error. For example, per RFC 3, a broker SHALL respond
with error number 38 "Function not implemented" if the topic string cannot
be matched to a service, or error number 113, "No route to host" if the
requested nodeid cannot be reached.

Although overlay networks use reliable transports between brokers,
exceptional conditions at the endpoints or at intervening broker instances
MAY cause messages to be lost. It is the client’s responsibility to
implement any timeouts or other mitigation to handle missing or delayed
responses.


Disconnection
~~~~~~~~~~~~~

If a client aborts with an RPC in progress, it or its proxy SHOULD send a
request to the server with a topic string of "*service*.disconnect".
The FLUX_MSGFLAG_NORESPONSE message flag SHOULD be set in this request.

It is optional for the server to implement the disconnect method.

If the server implements the disconnect method, it SHALL cancel any
pending RPC requests from the sender, without responding to them.

The server MAY determine the sender identity for any request, including
the disconnect request, by reading the first source-address routing identity
frame (closest to routing delimiter frame) from the request message.
Servers which maintain per-request state SHOULD index it by sender identity
so that it can be removed upon receipt of the disconnect request.


Cancellation
~~~~~~~~~~~~

A service MAY implement a method which allows pending requests on its
other methods to be canceled.  If implemented, the cancellation method
SHOULD accept a JSON object payload containing a "matchtag" key with integer
value.  The sender of the cancellation request and the matchtag from its
payload MAY be used by the service to uniquely identify a single request
to be canceled.

The client SHALL set the FLUX_MSGFLAG_NORESPONSE message flag in the
cancellation request and the server SHALL NOT respond to it.

If the canceled request did not set the FLUX_MSGFLAG_NORESPONSE message flag,
the server SHOULD respond to it with error number 125 (operation canceled).
