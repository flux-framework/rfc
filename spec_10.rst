.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_10.html

10/Content Storage Service
==========================

This specification describes the Flux content storage service
and the messages used to access it.

-  Name: github.com/flux-framework/rfc/spec_10.rst

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

-  :doc:`11/Key Value Store Tree Object Format v1 <spec_11>`


Goals
-----

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
explored in Venti, Git, and Camlistore (see References below).


Implementation
--------------

The content service SHALL be implemented as a distributed cache with a
presence on each broker rank. Each rank MAY cache content according
to an implementation-defined heuristic.

Ranks > 0 SHALL make transitive load and store requests to their parent on
the tree based overlay network to fill invalid cache entries, and flush
dirty cache entries.

Rank 0 SHALL retain all content previously stored by the instance.

Rank 0 MAY extend its cache with an OPTIONAL backing store, the details
of which are beyond the scope of this RFC.


Content
~~~~~~~

Content SHALL consist of from zero to 1,048,576 bytes of data.
Content SHALL NOT be interpreted by the content service.

Note: The blob size limit was temporarily increased to one gigabyte to
avoid failures resulting from extreme workloads.  The original limit will
be restored once KVS *hdir* objects are implemented.


Blobref
~~~~~~~

Each unique, stored blob of content SHALL be addressable by its blobref.
A blobref SHALL consist of a string formed by the concatenation of:

-  the name of hash algorithm used to store the content

-  a hyphen

-  a message digest represented as a lower-case hex string

Example:

::

   sha1-f1d2d2f924e986ac86fdf7b36c94bcdf32beec15

Note: "blobref" was shamelessly borrowed from Camlistore
(see References below).


Store
~~~~~

A store request SHALL be encoded as a Flux request message with the blob
as raw payload (blob length > 0), or no payload (blob length = 0).

A store response SHALL be encoded as a Flux response message with
NULL-terminated blobref string as raw payload, or an error response.

A request to store content that exceeds the maximum size SHALL
receive error number 27, "File too large", in response.

After the successful store response is received, the blob SHALL be
accessible from any rank in the instance.


Load
~~~~

A load request SHALL be encoded as a Flux request message with
NULL-terminated blobref string as raw payload.

A load response SHALL be encoded as a Flux response message with blob
as raw payload (blob length > 0), no payload (blob length = 0),
or an error response.

A request to load unknown content SHALL receive error number 2,
"No such file or directory", in response.


Flush
~~~~~

A flush request SHALL cause the local rank content service to finish
storing any dirty cache entries. A flush response SHALL NOT be sent
until there are no dirty cache entries.

On rank 0, "dirty" SHALL be defined as "not stored on a backing store".
On rank > 0, "dirty" SHALL be defined as "not stored on rank 0".

A flush request SHALL receive error number 38, "Function not implemented",
on rank 0 if a backing store is not configured.


Dropcache
~~~~~~~~~

A dropcache request SHALL cause the local content service to drop all
non-essential entries from its cache.


Garbage Collection
~~~~~~~~~~~~~~~~~~

References to content are the responsibility of the Flux key Value Store.
Content that the KVS no longer references MAY NOT be removed while the Flux
instance is running.

A Flux instance that is configured to restart saves content before shutting
down.  The shutdown process, after the KVS service has been stopped, MAY choose
to omit content that the final KVS root does not reference as a form of
garbage collection.


References
----------

-  `Camlistore is your personal storage system for life <https://camlistore.org/>`__.

-  `Venti: a new approach to archival storage <http://doc.cat-v.org/plan_9/4th_edition/papers/venti/>`__, Bell Labs, Quinlan and Dorward.

-  `git reference manual <http://git-scm.com/doc>`__
