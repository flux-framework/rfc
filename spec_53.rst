.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_53.html

53/Flux Message Protocol Version 2
##################################

This specification describes the format of Flux message broker
messages, Version 2.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_53.rst
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
- :doc:`spec_39`
- :doc:`spec_42`

Background
**********

RFC 3 defines version 1 of the Flux message format.  It did not anticipate
message signatures, mixed structured and unstructured payloads, or
future message protocol extensions.

All version 1 messages are translatable to version 2.

Goals
*****

Authenticate the sender end to end
  Allow the sender-owned portion of a request to be signed, so a service can
  authenticate the sender without trusting intermediate brokers.  To make
  clear what a signature covers, version 2 places fields chosen by the sender
  and fields assigned in transit in separate headers.

Carry binary and structured data efficiently
  Protocols that combine structured data with binary data must currently
  encode the binary data, for example as base64 within JSON, as RFC 42 I/O
  does.  Version 2 allows an opaque attachment alongside the payload.

Leave room to grow without another version
  Provide 32-bit flag fields in both headers, and allow either header to be
  extended with new fields, so future features can be added without
  defining a version 3.

Allow for phased upgrade
  Flux components may support both version 1 and version 2 messages during
  transition, supporting a phased rollout, such as:

  #. Version 1 and 2 coexist within a Flux instance: version 1 is the
     instance default and version 2 use is limited to internal protocols.
  #. Version 2 is the instance default, with version 1 peers supported
     via translation.
  #. Version 1 is deprecated.

Terminology
***********

sender
  The component that creates a message.

forwarder
  A broker, connector, or other component that relays a message without being
  its final recipient.

receiver
  The final recipient of a message.

service
  The receiver of a request.

client
  The sender of a request.

The sender of a signed message is also its *signer*.

Implementation
**************

Except where this document states otherwise, the semantics of version 2
messages SHALL be the same as those of version 1 messages described in
RFC 3.  This includes message types, request routing, the meaning of the
*nodeid*, *matchtag*, *errnum*, and *sequence* fields, route stack
handling, and the assignment of message credentials.

Message Structure
=================

A version 2 message SHALL consist of the following ordered parts:

.. list-table::
  :header-rows: 1
  :widths: 22 20 58

  * - Part
    - Owner
    - Presence
  * - routes
    - transport
    - zero or more, only if *tflag-route* is set
  * - route delimiter
    - transport
    - if *tflag-route* is set
  * - topic
    - sender
    - if *cflag-topic* is set
  * - payload
    - sender
    - if *cflag-payload* is set
  * - attachment
    - sender
    - if *cflag-attachment* is set
  * - signature
    - neither
    - if *cflag-signed* is set
  * - content header
    - sender
    - always
  * - transport header
    - transport
    - always, as the last part

The boundaries between message parts SHALL be preserved by message
transports, as in RFC 3.

routes
  Each route SHALL be a non-empty message part identifying one route hop,
  with the same meaning as in RFC 3.

route delimiter
  An empty message part that separates the routes from the remaining parts.

topic
  A NUL-terminated string representing an event topic or an RPC service
  endpoint, with the same meaning as in RFC 3.

payload
  Zero or more bytes of user-specific content.  The payload conventions of
  RFC 3 SHALL apply.

attachment
  Zero or more bytes of opaque content.  The message protocol SHALL NOT
  interpret the attachment.  Its meaning is defined by the protocol that
  uses the message.  A message MAY have an attachment with or without a
  payload.

signature
  A NUL-terminated RFC 39 signature string.  See `Signed Messages`_.

content header
  A header containing fields chosen by the sender.  See `Content Header`_.

transport header
  A header containing fields assigned or modified in transit.  See
  `Transport Header`_.

Parsing
-------

A receiver SHALL locate message parts by position, starting from the end of
the message:

#. The last part SHALL be the transport header.

#. The next-to-last part SHALL be the content header.

#. If *cflag-signed* is set, the preceding part SHALL be the signature.

#. If *cflag-attachment* is set, the preceding part SHALL be the attachment.

#. If *cflag-payload* is set, the preceding part SHALL be the payload.

#. If *cflag-topic* is set, the preceding part SHALL be the topic.

#. If *tflag-route* is set, the preceding part SHALL be the route delimiter,
   and all parts before it SHALL be routes.  If *tflag-route* is clear, there
   SHALL be no preceding parts.

A receiver SHALL reject with EPROTO any message that does not exactly match
this structure, including one with extra or missing parts.

A forwarder SHALL NOT apply this check.  It SHALL locate only the routes, the
route delimiter, the topic, and the two headers.  It SHALL pass every part
between the topic and the content header through unchanged, without
determining which of those parts are present.

.. note::

   The content header always occupies the same position, so a receiver can
   determine whether a message is signed before locating any other
   sender-owned part.  A message whose signature has been removed, or whose
   parts have been shifted, fails the structure check or signature
   verification.  It is never accepted as a different message.

Protocol Headers
================

The content header has 16 bytes of fixed fields and the transport header has
20.  Either header MAY be longer, as described in `Header Extensions`_.  All
multi-byte integers SHALL be encoded in network (big endian) byte order.
The *cflags* and *tflags* fields SHALL be interpreted as 32-bit unsigned
integers.

.. code-block:: ABNF

   CONTENT          = c-request / c-response / c-event / c-control

   c-request        = magic version %x01 cpad cflags nodeid   matchtag
                      c-extension
   c-response       = magic version %x02 cpad cflags errnum   matchtag
                      c-extension
   c-event          = magic version %x04 cpad cflags unused   unused
                      c-extension
   c-control        = magic version %x08 cpad cflags type     status
                      c-extension

   TRANSPORT        = magic version tpad tflags userid rolemask sequence
                      t-extension

   ; Constants
   magic            = %x8E          ; magic cookie (same as version 1)
   version          = %x02          ; Flux message version

   ; Content header padding
   cpad             = %x00

   ; Content flags: a bitmask of cflag- values below
   cflags           = 4OCTET
   cflag-topic      = %x00.00.00.01 ; message has topic string part
   cflag-payload    = %x00.00.00.02 ; message has payload part
   cflag-attachment = %x00.00.00.04 ; message has attachment part
   cflag-noresponse = %x00.00.00.08 ; request should receive no response
   cflag-upstream   = %x00.00.00.10 ; request should be routed upstream
                                    ;   of nodeid sender
   cflag-private    = %x00.00.00.20 ; event is requested to be private
                                    ;   to sender, instance owner
   cflag-streaming  = %x00.00.00.40 ; request/response is part of
                                    ;   streaming RPC
   cflag-user1      = %x00.00.00.80 ; user defined flag
   cflag-signed     = %x00.00.01.00 ; message has signature part

   ; Transport flags: a bitmask of tflag- values below
   tflags           = 4OCTET
   tflag-route      = %x00.00.00.01 ; message has route delimiter part

   ; Userid assigned at message ingress
   userid           = 4OCTET / userid-unknown
   userid-unknown   = %xFF.FF.FF.FF

   ; Role bitmask assigned at message ingress
   rolemask         = 4OCTET

   ; Event sequence number assigned by the rank 0 broker; zero otherwise
   sequence         = 4OCTET

   ; Matchtag to correlate request/response
   matchtag         = 4OCTET / matchtag-none
   matchtag-none    = %x00.00.00.00

   ; Target node ID
   nodeid           = 4OCTET / nodeid-any / nodeid-upstream
   nodeid-any       = %xFF.FF.FF.FF
   nodeid-upstream  = %xFF.FF.FF.FE ; RPC interface only, as in RFC 3

   ; UNIX errno
   errnum           = 4OCTET

   ; Control message type and status
   type             = 4OCTET
   status           = 4OCTET

   ; Unused 4-byte field
   unused           = %x00.00.00.00

   ; Reserved transport space
   tpad             = 2OCTET

   ; Header extensions (see Header Extensions)
   c-extension      = *OCTET
   t-extension      = *OCTET

Content Header
--------------

The content header contains only fields chosen by the sender.  Forwarders
SHALL NOT modify it.

The *cflags* bit positions differ from those of the version 1 flags.  The
correspondence between them is given in `Correspondence with Version 1`_.
Route presence is a transport flag in version 2.

Undefined *cflags* bits and the *cpad* field SHALL be zero.  A receiver
SHALL reject a message with an undefined *cflags* bit set, or a nonzero
*cpad*, with EPROTO, because a content field may change the meaning of a
message.

This check applies only to the receiver.  A forwarder SHALL NOT reject a
message because of an undefined *cflags* bit, a nonzero *cpad*, or an
unrecognized content header extension field, and SHALL treat message parts
that it does not recognize as opaque.

A forwarder reads the content header only to route and deliver the message.
It reads the message *type*, and *nodeid* and *cflag-upstream* for a request,
to choose a destination, and *cflag-topic* to locate the topic part.  It MAY
read *matchtag* to track an outstanding RPC, so that it can generate an error
response if a peer disappears.  It SHALL ignore the remaining fields.

Because a forwarder ignores the content flags it does not define, a content
flag SHALL NOT change how a forwarder routes or delivers a message.  A future
feature that changes forwarding SHALL use a mechanism that forwarders cannot
ignore, such as a transport flag.

.. note::

   Because a forwarder reads so few content header fields, it can relay a
   message that uses content flags it does not define.  This allows a newer
   Flux instance launched within an older one to use flags that the older
   instance's brokers do not know.

Transport Header
----------------

The transport header contains fields that forwarders assign or modify in
transit.  It SHALL be the last part of every version 2 message, so that a
receiver can identify the message version from the last part alone.

The *userid* and *rolemask* fields SHALL be assigned when the message is
accepted by a broker, and the *sequence* field SHALL be assigned by the
rank 0 broker for events, all as in RFC 3.  The transport header fields are
asserted by brokers and are not covered by signatures.

Header Extensions
-----------------

Either header MAY be longer than its fixed fields.  A receiver SHALL locate
the fixed fields by their offsets, and SHALL NOT assume that a header ends
after them.

Content header
  Bytes after the fixed fields SHALL be present only if a content flag
  defined by a future revision of this specification requires them, and
  their format SHALL be defined with that flag.  A receiver SHALL reject
  with EPROTO a content header that is longer than its content flags
  account for.

  Because the content header contributes to the message digest, extension
  fields in it are covered by signatures.

Transport header
  Bytes after the fixed fields are reserved for future revisions of this
  specification.  The transport header is transport-owned, so a broker, not a
  sender, adds any extension field.  This revision defines none, and a broker
  SHALL NOT include one until a future revision defines it.  Forwarders SHALL
  pass extension bytes through unchanged, and receivers SHALL ignore the ones
  they do not understand.

  A future revision that defines a transport header extension field SHALL
  observe the following rules, so that a receiver can locate the fields it
  understands:

  - Each extension field SHALL be governed by a *tflags* bit, and SHALL be
    present only if that bit is set.

  - Extension fields SHALL appear in ascending order of the *tflags* bit
    that governs them, and a future revision SHALL allocate new bits above
    those already defined.

  - The definition of each field SHALL fix its size, or SHALL define a length
    prefix for it.

  - A receiver SHALL stop parsing at the first extension field governed by
    a *tflags* bit that it does not define, and SHALL ignore that field and
    all bytes following it.

  Transport header extension fields do not contribute to the message digest,
  so they are not covered by signatures.

Reserved Transport Fields
-------------------------

The *tpad* field and the undefined *tflags* bits are reserved.  The broker
that accepts the message SHALL set them to zero, forwarders SHALL pass them
through unchanged, and receivers SHALL ignore them.

.. note::

   These rules let future features be added without a new message version.
   A new content flag makes older receivers reject messages that use it,
   which is the safe outcome for anything that changes a message's meaning.
   A new transport flag or transport extension field is carried through
   older forwarders and ignored by older receivers.

Message Types
=============

The rules for each message type are those of RFC 3, restated here in terms
of the version 2 fields.

Request
  The message SHALL set *tflag-route* and include a route delimiter, and MAY
  include routes.  It SHALL include a topic string.  It MAY include a payload
  and attachment.  It MAY set *cflag-upstream*, *cflag-noresponse*, and
  *cflag-streaming*.  It MAY be signed.  Requests SHALL be routed as in
  RFC 3, using *nodeid* and *cflag-upstream*.

Response
  The message SHALL set *tflag-route* and include the route delimiter and
  routes copied from the request.  It SHALL include the topic string and
  *matchtag* copied from the request.  It MAY include a payload and
  attachment.  It SHALL include an *errnum*.  It SHALL NOT be signed in this
  revision.  See `Signed Messages`_.

Event
  The message SHALL NOT set *tflag-route* and SHALL NOT include routes or a
  route delimiter.  It SHALL include a topic string.  It MAY include a
  payload and attachment.  It MAY set *cflag-private*.  It SHALL NOT be
  signed in this revision.  Events SHALL only be published by the rank 0
  broker, as in RFC 3.

Control
  The message SHALL NOT set *tflag-route* and SHALL NOT include routes, a
  route delimiter, a topic string, a payload, or an attachment.  It SHALL NOT
  be signed.  It SHALL NOT be routed.

Signed Messages
===============

A request MAY be *signed* by its sender, so that the service can
authenticate the sender's userid and verify that the sender-owned parts were
not modified in transit, without trusting the forwarders.

Events and control messages SHALL NOT be signed in this revision, as
`Message Types`_ requires.

Responses SHALL NOT be signed in this revision.  Adding signed responses
later does not require a new message version, because *cflag-signed* and the
signature part are defined for any message.

Message Digest
--------------

The *message digest* SHALL be the SHA-256 digest of the concatenation of
the following items, in order.  Each item SHALL be encoded as a 4-byte
length in network byte order followed by the item's bytes:

#. The topic part, including its terminating NUL, if *cflag-topic* is set.

#. The payload, if *cflag-payload* is set.

#. The attachment, if *cflag-attachment* is set.

#. The content header, including any extension fields.

The routes, route delimiter, signature, and transport header SHALL NOT
contribute to the message digest.

Signature
---------

The signature part SHALL be an RFC 39 signature of the *message* class whose
payload is the 32-byte message digest.  The signing mechanism SHALL be
selected by the flux-security configuration, as for other RFC 39
signatures.

A *signature class* distinguishes signatures created for different purposes,
so that the properties required by each purpose may differ.  RFC 39 does not
yet define signature classes.  A future revision of RFC 39 is expected to
define the *message* class with the following properties, on which this
specification relies:

- A message-class signature has a limited lifetime, on the order of
  minutes, after which verification fails.

- A message-class signature cannot be verified as a signature of another
  class, nor a signature of another class as a message-class signature.

- Verification fails when the mechanism reports a replayed or expired
  credential.

.. note::

   A separate class is needed because the properties RFC 39 specifies today
   are those a signed jobspec requires, and they are too weak for messages.
   A job request may be pending for days and may be verified by several
   parties on the same host, so RFC 39 imposes a long, site-configured
   time-to-live and treats MUNGE's ``EMUNGE_CRED_EXPIRED`` and
   ``EMUNGE_CRED_REPLAYED`` as success.  A message is verified once, by one
   receiver, shortly after it is sent, so it can afford a short lifetime and
   replay rejection.  Relaxing these for jobspec is necessary; relaxing them
   for messages would weaken message signatures for no reason.

   The lifetime bounds how long a captured signature remains useful, but it
   does not by itself guarantee that a signature is accepted only once.  See
   `Security Considerations`_.

Signing
-------

To sign a message, the sender SHALL:

#. Construct the topic, payload, attachment, and content header in their
   final form, with *cflag-signed* set in the content header.

#. Compute the message digest, including the digest of the corresponding
   request if the message is a response.

#. Create a message-class RFC 39 signature over the digest.

#. Insert the signature part immediately before the content header.

Any subsequent change to a sender-owned part invalidates the signature.

A sender that needs to sign more than one message, for example the same
request to several ranks, SHALL sign each message separately.

Verification
------------

A service that requires authentication of a request SHALL perform the
following steps.  To *reject* a message with an error is to handle it as
described in `Errors`_.

#. Reject the message with EPERM if *cflag-signed* is clear.

#. Reject the message with EPROTO if the signature part is not a
   NUL-terminated string.

#. Verify the signature as a message-class RFC 39 signature, accepting only
   mechanisms permitted by the flux-security configuration, and obtain the
   signing userid and the signed digest.  Reject the message with EPERM if
   verification fails.

#. Reject the message with EPROTO if the signed digest is not 32 bytes.

#. Recompute the message digest from the received message.  Reject the
   message with EPERM if it differs from the signed digest.

Only the final receiver of a signed message SHALL verify it.  Forwarders
SHALL NOT verify signed messages.  A receiver that handles a message more
than once, for example after requeuing it, SHALL verify it only once and
reuse the result.

.. note::

   Under the message class, a mechanism that detects replays, such as MUNGE,
   rejects a second verification of the same signature on the same host.
   This differs from the job request case, where RFC 39 directs that such
   errors be ignored, because several parties on a host may need to verify
   the same credential.  A request has exactly one receiver, so verifying
   only at that receiver, and only once, avoids rejecting legitimate
   messages.

A receiver that does not require authentication SHALL NOT reject a message
because it is signed, or because its signature uses a particular mechanism.
It MAY ignore the signature, but SHALL still apply the structure checks in
`Parsing`_.

.. note::

   This lets a sender sign whenever authentication might be required,
   without determining whether the receiver requires it.  In particular, a
   client need not check whether it runs as the instance owner.  An
   implementation built without flux-security signs with the ``none``
   mechanism, which receivers that do not require authentication accept
   and receivers that do require it reject.

   An implementation MAY also sign with ``none`` when the sender is the
   instance owner, to avoid the cost of a real mechanism, as is done for
   job requests.  This is safe even though the sender learns the instance
   owner from the broker: if the broker reports it falsely, the receiver
   rejects the ``none`` signature if authentication is required.

Requiring Signatures
--------------------

A receiver SHALL decide whether to require signed messages using information
that does not depend on the broker or any other forwarder.  In particular, a
receiver SHALL NOT base this decision on broker attributes or on the
transport header.

.. note::

   The job shell is an example.  A guest's job shell is started by
   flux-imp(1), so a ``kill (getppid (), 0)`` permission check fails, and
   the shell treats its broker as untrusted.  A shell running as the
   instance owner has the broker as its parent, the check succeeds, and the
   shell relies on the transport credentials instead.

Authorization
-------------

After successful verification, the receiver MAY treat the signing userid as
the authenticated sender of the message.

The signature conveys identity only.  A receiver SHALL base authorization of
a signed message on the signing userid.  It SHALL NOT use the transport
*rolemask* to grant privilege to a signed message, except where the
receiving service explicitly defines how proxied requests are authorized.

If the signing userid differs from the transport *userid*, the receiver
SHOULD reject the message with EPERM unless the service explicitly supports
proxied requests.

The *nodeid* of a signed request is covered by the signature.  However, a
receiver typically learns its own rank from its broker, so comparing the
signed *nodeid* with its rank is a consistency check, not a security
property.  See `Security Considerations`_.

Errors
------

A request rejected by verification SHALL receive an RFC 6 error response
carrying the error number given in `Verification`_.  If *cflag-noresponse* is
set, the request SHALL be discarded instead, and MAY be logged.

Responses are not signed in this revision, so a client verifies nothing and
handles every response as in RFC 6.  A client MAY use the *errnum* of an
error response to select a fallback, including sending the request again in
a form a service accepted before this specification.  Which forms are
accepted is a matter for the service, as `Verification`_ provides.

.. note::

   A protocol in transition may have clients that fall back and services
   that accept more than one form of signature.  A forwarder can forge an
   error to drive a client to its fallback, so a service SHOULD stop
   accepting a form once its clients no longer need it.  The EPROTONOSUPPORT
   of `Transition`_ is an example of a fallback that costs nothing: a service
   that requires signatures rejects an unsigned request on its own
   authority, so forging the error gains a forwarder nothing.

Transport Rules
===============

The following rules apply to brokers, connectors, and any other component
that forwards Flux messages.

- A forwarder MAY add or remove routes and the route delimiter, and MAY set
  *tflag-route*, *userid*, *rolemask*, and *sequence* as described in this
  document and RFC 3.

- A forwarder SHALL NOT modify the topic or the content header, and SHALL
  pass every part between them through unchanged.  It therefore adds no
  signature and removes none.

- When an implementation derives a response from a request, it SHALL NOT
  copy the signature part, and SHALL clear *cflag-signed* in the derived
  response.

Coexistence with Version 1
==========================

Version Dispatch
----------------

Both versions end with a header that begins with the magic value ``%x8E``
followed by the version.  A receiver SHALL determine the version of a
message from the second byte of its last part and parse the message
according to RFC 3 or this specification.

A receiver that supports version 2 SHALL continue to accept version 1
messages until version 1 is fully deprecated.

Correspondence with Version 1
-----------------------------

Every property of a version 1 message SHALL be representable in version 2,
so that an implementation can translate any version 1 message to version 2
during transition.  Any future changes to version 1 SHALL preserve this
property.  The correspondence is:

- The topic, payload, and routes are the same parts in both versions.

- Each version 1 flag other than *flag-route* corresponds to the content
  flag of the same name: *flag-topic* to *cflag-topic*, *flag-payload* to
  *cflag-payload*, and likewise for *noresponse*, *upstream*, *private*,
  *streaming*, and *user1*.  Version 1 *flag-route* corresponds to
  *tflag-route*.

- The message type, *nodeid*, *errnum*, *matchtag*, control *type*, and
  control *status* are content header fields, and *userid*, *rolemask*, and
  event *sequence* are transport header fields.

A version 2 message with *cflag-signed* or *cflag-attachment* set, or with
content header extension fields, has no version 1 equivalent.

Transition
----------

The plan for transitioning to version 2 is out of scope, but the design of
version 2 messages SHALL support a phased transition, such as the one outlined
in the goals section.

A component SHALL NOT send a version 2 message to a peer unless it knows the
peer supports version 2. A version 2 request that cannot be delivered for
this reason SHALL receive an error response with EPROTONOSUPPORT (93).

Message Framing
===============

Version 2 messages SHALL use the message framing and connection security of
RFC 3 unchanged.  Each part, including the signature and both headers, is
framed as an ordinary message part.

Security Considerations
***********************

Scope of signatures
  A signature provides sender authentication and integrity of the
  sender-owned parts of a request.  It provides no confidentiality, and no
  assurance about routing, delivery, transport header fields, or
  broker-generated messages such as error responses and disconnect
  notifications.

Unauthenticated responses
  Responses are not signed, so a client cannot authenticate one, and a
  forwarder can drop a response, substitute one, or simulate any failure.  A
  client that acts on an *errnum*, for example by concluding that a service
  is absent or a rank unreachable, acts on unauthenticated information.  A
  protocol that needs an authenticated result SHALL carry it end to end
  itself, for example in a payload signed by the service.

Credential mixing
  The transport credentials of a signed message are controlled by forwarders
  and may not match the signer.  A receiver that authenticates using the
  signature but authorizes using the transport *rolemask* creates a confused
  deputy.  `Authorization`_ prohibits this.

Replay within the signature lifetime
  The message class bounds a signature's lifetime but does not guarantee
  single acceptance.  A forwarder that captures a signed request can resend
  it within the lifetime.  A mechanism with replay detection, such as
  MUNGE, rejects a resend to the same host, but not to another host.  This
  depends on the message class not ignoring the mechanism's replay errors, as
  RFC 39 does for job requests.  Signatures still ensure that only requests
  the signer actually made are accepted, but such a request may be accepted
  more than once.  For example,
  an RFC 42 ``exec`` request could re-run a command, and a ``write`` request
  could repeat input to a running interactive process.  Protocols that
  require at-most-once semantics SHALL provide them, for example with
  identifiers in the signed payload.

Destination binding
  A request addressed with *nodeid-any* or *cflag-upstream* leaves the
  choice of destination to the transport, so a forwarder can deliver it, or
  a replay of it, to any receiver offering the service.  This is expected.
  A request addressed to a specific rank is signed with that rank, but a
  receiver typically learns its own rank from its broker, so the signature
  alone does not enforce the destination.  Protocols that need it enforced
  SHOULD include in the signed payload an identity the receiver can verify
  without its broker, such as a hostname.

Response redirection
  A forwarder that can modify routes can resend a signed request under its
  own route and receive the responses.  Signatures do not hide the contents
  of a response.  Protocols that need response confidentiality must provide
  it themselves.

Session ownership
  A service that tracks sessions by route identity alone can be confused by
  rewritten routes.  Services that accept signed requests SHOULD associate
  sessions with the signing userid as well as the route and *matchtag*.

Broker-generated notifications
  Disconnect notifications and similar messages are generated by brokers and
  are unsigned.  A forwarder able to forge them can terminate other clients'
  sessions.  This is a denial-of-service risk that signing does not address.

Downgrade
  Removing the signature from a message causes it to fail the structure
  check, but a forwarder can always send an unsigned message of its own.
  A receiver that requires authentication must therefore reject unsigned
  messages, as `Verification`_ step 1 requires.

Mechanism trust
  The strength of a signature depends on the configured mechanism.  For
  MUNGE, anyone holding the realm key, or with root access on any host
  in the realm, can forge signatures.  The ``none`` mechanism provides no
  authentication.  It is appropriate where receivers do not require
  signatures, such as single-user instances and builds without
  flux-security.

Clocks
  Signature lifetimes depend on reasonably synchronized wall clocks across
  hosts.

Cost
  Signing may require a round trip to a local daemon, such as munged, for
  each message, which may be significant for high-rate message streams.

Open Issues
***********

This section is intended to be removed before the specification leaves the
raw state.

#. Define how a version 1 peer is detected and supported by a Flux instance
   that is using version 2 as the default message format.

#. Define the message class in RFC 39, including its lifetime, its
   configuration, and how each mechanism meets it, and implement it in
   flux-security.  In particular, message class verification with the MUNGE
   mechanism SHALL NOT treat ``EMUNGE_CRED_REPLAYED`` or
   ``EMUNGE_CRED_EXPIRED`` as success, as RFC 39 currently directs for job
   requests.

#. Consider binding message-class signatures to the receiver's uid where the
   mechanism supports it, such as MUNGE's uid restriction.

#. Amend RFC 42 to accept version 2 message signatures, deprecate its
   in-payload signatures, and carry I/O data in attachments.

#. Decide whether to define signed responses.  Signing them does not
   authenticate the outcome of an RPC on its own: brokers generate error
   responses that no component can sign, such as the ENOSYS or EHOSTUNREACH
   that follows a service being unloaded or its route being lost, so a client
   must accept unsigned error responses and a forwarder can simulate any
   failure.  A signed response also needs binding to the request it answers,
   since a *matchtag* is unique only to a client and is reused.  Consider as
   well whether streaming RPCs need a protocol-independent response sequence
   number to detect dropped or reordered responses.

References
**********

- `FIPS 180-4: Secure Hash Standard (SHS) <https://csrc.nist.gov/pubs/fips/180-4/upd1/final>`__, NIST, August 2015.
