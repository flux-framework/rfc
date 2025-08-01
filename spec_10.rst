.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_10.html

10/Content Storage Service
##########################

This specification describes the Flux content storage service
and the messages used to access it.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_10.rst
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
- :doc:`spec_11`

Goals
*****

The Flux content storage service is the storage layer for the Flux Key Value
Store (KVS).  The goals of the content storage service are:

-  Provide storage for opaque binary blobs.

-  Once stored from any broker rank, content is available to all broker ranks.

-  Stored content is immutable.

-  Content may not be removed while the Flux instance is running.

-  Stored content is addressable by its message digest, computed using a
   cryptographic hash.

-  The cryptographic hash algorithm is configurable per instance.

This kind of store has interesting and well-understood properties, as
explored in Venti, Git, and Perkeep (see References below), for example:

-  Writes are idempotent

-  De-duplication is automatic

-  The address may be used to check the integrity of the addressed content

Implementation
**************

The content service SHALL be implemented as a distributed cache with a
presence on each broker rank. Each rank MAY cache content according
to an implementation-defined heuristic.

Ranks > 0 SHALL make transitive load and store requests to their parent on
the tree based overlay network to fill invalid cache entries, and flush
dirty cache entries.

Rank 0 SHALL retain all content previously stored by the instance.

Rank 0 MAY extend its cache with an OPTIONAL backing store, the details
of which are beyond the scope of this RFC.

The content service SHALL NOT be accessible by guest users.

Hash Algorithm
==============

A Flux instance SHALL select a hash algorithm at startup.  This selection
MUST NOT change throughout the lifetime of the instance.

The configured algorithm SHALL be made available to Flux components via the
``content.hash`` broker attribute.

The hash algorithm:

-  MUST have a high enough collision resistance so that the probability of
   storing two different blobs with the same address is extremely unlikely

-  is RECOMMENDED to have high space efficiency

-  is RECOMMENDED to have low computational overhead

Content
=======

Content SHALL consist of from zero to 1,048,576 bytes of data.
Content SHALL NOT be interpreted by the content service.

Note: The blob size limit was temporarily increased to one gigabyte to
avoid failures resulting from extreme workloads.  The original limit will
be restored once KVS *hdir* objects are implemented.

Address
=======

Each unique, stored blob of content SHALL be addressable by its hash digest.

A human-readable *blobref* MAY be used as an alternate representation of
the hash digest.  A blobref SHALL consist of a string formed by the
concatenation of:

-  the name of hash algorithm used to store the content

-  a hyphen

-  a message digest represented as a lower-case hex string

Example:

::

   sha1-f1d2d2f924e986ac86fdf7b36c94bcdf32beec15

Note: "blobref" was shamelessly borrowed from Perkeep (see References below).

Store
=====

A store request SHALL be encoded as a Flux request message with the blob
as raw payload (blob length > 0), or no payload (blob length = 0).

A store response SHALL be encoded as a Flux response message with
the message digest as raw payload, or an error response.

A request to store content that exceeds the maximum size SHALL
receive error number 27, "File too large", in response.

After the successful store response is received, the blob SHALL be
accessible from any rank in the instance.

Load
====

A load request SHALL be encoded as a Flux request message with
message digest as raw payload.

A load response SHALL be encoded as a Flux response message with blob
as raw payload (blob length > 0), no payload (blob length = 0),
or an error response.

A request to load unknown content SHALL receive error number 2,
"No such file or directory", in response.

Validate
========

A validate request SHALL be encoded as a Flux request message with
message digest as raw payload.

A validate response SHALL be encoded as a Flux response message with
no payload (digest validated) or an error response.

A request with an unknown digest SHALL receive error number 2,
"No such file or directory", in response.

Flush
=====

A flush request SHALL cause the local rank content service to finish
storing any dirty cache entries. A flush response SHALL NOT be sent
until there are no dirty cache entries.

On rank 0, "dirty" SHALL be defined as "not stored on a backing store".
On rank > 0, "dirty" SHALL be defined as "not stored on rank 0".

A flush request SHALL receive error number 38, "Function not implemented",
on rank 0 if a backing store is not configured.

Dropcache
=========

A dropcache request SHALL cause the local content service to drop all
non-essential entries from its cache.


Garbage Collection
==================

References to content are the responsibility of the Flux Key Value Store.
Content that the KVS no longer references MAY NOT be removed while the Flux
instance is running.

A Flux instance that is configured to restart saves content before shutting
down.  The shutdown process, after the KVS service has been stopped, MAY choose
to omit content that the final KVS root does not reference as a form of
garbage collection.

References
**********

-  `Perkeep lets you permanently keep your stuff, for life. <https://en.wikipedia.org/wiki/Perkeep>`__.

-  `Venti: a new approach to archival storage <https://doc.cat-v.org/plan_9/4th_edition/papers/venti/>`__, Bell Labs, Quinlan and Dorward.

-  `git reference manual <https://git-scm.com/doc>`__
