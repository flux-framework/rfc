49/Flux ID Map
==============

The Flux idmap is a compact encoding of a mapping from integer keys
to sets of integers.

- Name: github.com/flux-framework/rfc/spec_49.rst
- Editor: Jim Garlick <garlick@llnl.gov>
- State: raw

Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in `RFC 2119`_.

Related Standards
-----------------

* :doc:`20/Resource Set Specification <spec_20>`
* :doc:`22/Idset String Representation <spec_22>`
* :doc:`34/Flux Task Map <spec_34>`

Background
----------

The Flux taskmap (RFC 34) defines a compact format for mapping job task
ranks to node IDs. It encodes a function from a set of integer keys
(node indices) to sets of integer values (task ranks), exploiting
regularity in common distributions to achieve compactness at scale.

The Flux idmap generalizes this concept to functions from integer keys
to sets of integers, without assuming that the mapped values are
contiguous starting from a computed base. This is necessary when the
mapped values cannot be derived from the key alone, such as when they
are assigned by an external authority and may begin at an arbitrary
offset or contain gaps.

Each key maps to a set of integers. Within a single map block, the
integers mapped to each key form a contiguous range. Non-contiguous
sets are expressed by using multiple blocks with the same key range,
whose contributions are unioned.

An idmap can be naively represented as a list of entries of the form
``key:idset``, where ``key`` is an integer key and ``idset`` is an
RFC 22 idset of mapped values for that key, with entries separated by
semicolons. We use this format when defining test vectors and refer to
it as the *raw idmap*.

Design Rationale
----------------

.. note::

   This section is informative and does not affect the normative
   requirements of this specification.

The taskmap format (RFC 34) achieves compactness by deriving mapped
values implicitly from the key via ``nodeid * ppn``. This works when
the keys and values are related by a simple linear function — for
example, when task ranks are assigned to nodes in block or cyclic order
starting from zero. It fails when the mapped values are assigned by an
external authority and cannot be derived from the key alone.

A concrete example arises when mapping hardware resource indices such as
CPU core IDs or GPU device IDs to logical resource keys. On multi-die
processor architectures, the operating system may assign physical core
IDs that are non-contiguous across dies and do not start from a
computed base. For example, a processor with three compute dies of
eight cores each might expose physical core IDs 0-7, 48-55, and 96-103
rather than 0-7, 8-15, and 16-23. The offset between die-local core ID
ranges is determined by the hardware and firmware, not by the key, so
it cannot be recovered from ``key * cores_per_die``.

A naive solution is to enumerate the mapped values explicitly for each
key. This is correct but sacrifices compactness. On a large uniform
system where thousands of identical keys share the same value layout,
explicit enumeration requires repeating the same information once per
key. The storage cost grows linearly with key count even when the
underlying mapping is perfectly regular.

The idmap addresses this by making ``baseid`` and ``stride`` explicit
parameters of each block rather than deriving them from the key. A
single block can then describe a regular mapping across any number of
consecutive keys regardless of where the value range begins. For the
three-die example above, three blocks — one per contiguous sub-range
of core IDs — compactly describe the full core mapping across all keys
regardless of how many keys there are.

Compactness under fragmentation is equally important. In systems where
a large number of idmap objects are stored persistently — for example,
as part of a job record in a key-value store — the cumulative storage
cost of many small allocations drawn from a large uniform pool is a
practical concern. When the set of keys is contiguous the mapping
remains compact. When the key set is fragmented — because some keys are
unavailable or have been allocated elsewhere — the storage cost
increases in proportion to the number of distinct contiguous sub-ranges
of keys, but never exceeds the storage cost of the raw idmap. This
graceful degradation property ensures that the worst-case storage cost
per idmap object is bounded by the number of keys, not by the structure
of the value space.

Together these properties allow the idmap to serve as a compact,
self-contained description of a one-to-many mapping from integer keys
to integer sets that can be stored efficiently at scale, reconstructed
without external reference, and interpreted correctly even when the
value space has gaps or non-zero offsets.

Goals
-----

* Represent functions from integer keys to sets of integers in a
  space-efficient manner when the mapping is regular or nearly regular.
* Generalize RFC 34 to handle non-contiguous and non-zero-based value
  ranges.
* Degrade gracefully under fragmentation of the key set: as regularity
  decreases, storage cost increases proportionally to the number of
  distinct contiguous sub-ranges of keys, reaching the storage cost of
  the raw idmap in the fully irregular case, but never exceeding it.
* Avoid the need for a custom parser by using JSON arrays.

Implementation
--------------

The Flux idmap SHALL be represented as a JSON array to avoid the need
for a custom parser. The array MUST contain zero or more *map blocks*.

A Flux idmap that contains zero map blocks SHALL indicate that the
mapping is unknown.

A Flux idmap encodes a function from integer keys to sets of integers.
Each map block describes a regular sub-mapping covering a contiguous
range of keys. The full mapping for any key is the union of value sets
contributed by all blocks whose key range includes that key.

A Flux idmap block is a JSON array with six REQUIRED integer elements:

start
    The first key in this block (zero-origin).

count
    The number of consecutive keys represented by this block.

baseid
    The first value in the mapped range for the first key of this
    block.

size
    The number of values mapped to each key.

stride
    The increment added to ``baseid`` for each successive key
    within the block.

repeat
    The number of times this block is logically repeated, advancing
    ``start`` by ``count`` and ``baseid`` by ``count * stride`` on
    each repetition.

The values mapped to key ``k`` within a block, where ``k`` =
``start`` + ``i`` for ``i`` in ``0..count-1``, before repeat
expansion, form the contiguous range::

    [baseid + (i * stride), baseid + (i * stride) + size - 1]

When ``repeat`` is greater than 1, the block is logically equivalent
to ``repeat`` consecutive blocks where the ``r``-th repetition
(zero-origin) has:

- ``start`` = original ``start`` + ``r * count``
- ``baseid`` = original ``baseid`` + ``r * count * stride``
- ``count``, ``size``, ``stride`` unchanged
- ``repeat`` = 1

.. note::

   The Flux idmap is a superset of the Flux taskmap (RFC 34). A
   RFC 34 taskmap block ``[nodeid, nnodes, ppn, repeat]`` is
   equivalent to the idmap block
   ``[nodeid, nnodes, nodeid*ppn, ppn, ppn, repeat]``. The idmap
   generalizes the taskmap by making ``baseid`` and ``stride``
   explicit rather than deriving them from ``nodeid * ppn``.

.. note::

   Each block maps each key to a single contiguous range of values.
   Keys requiring non-contiguous value sets MUST be covered by
   multiple blocks. The value sets contributed by all blocks for a
   given key are unioned to produce the final mapping for that key.

.. note::

   The storage cost of an idmap degrades gracefully under
   fragmentation of the key set. A perfectly regular mapping is
   represented by a single block. As the key set becomes less
   regular, additional blocks are required, but the storage cost
   increases only in proportion to the number of distinct contiguous
   sub-ranges of keys present. A fully irregular key set requires
   one block per key, reaching but never exceeding the storage cost
   of the raw idmap.

The Flux idmap MAY be wrapped in a JSON object when communicated
standalone. The JSON object has the following REQUIRED keys:

version
    The integer idmap version (1 for this RFC).

map
    The idmap array described above.

Example::

    {"version":1, "map":[[0,4,0,8,8,1],[0,4,48,8,8,1],[0,4,96,8,8,1]]}

Examples
--------

The following examples illustrate common mapping patterns. Raw idmap
notation uses ``key:idset`` pairs separated by semicolons, where
``key`` is an integer key and ``idset`` is an RFC 22 idset of mapped
values for that key.

**Block mapping, contiguous base IDs:**

Four keys, 8 values each, starting at 0, stride 8::

    [[0,4,0,8,8,1]]

Raw: ``0:0-7; 1:8-15; 2:16-23; 3:24-31``

**Block mapping, non-zero base:**

Four keys, 8 values each, starting at 48, stride 8::

    [[0,4,48,8,8,1]]

Raw: ``0:48-55; 1:56-63; 2:64-71; 3:72-79``

**Multiple non-contiguous ranges per key (two blocks):**

Four keys, each receiving values from two non-adjacent ranges::

    [[0,4,0,8,8,1],[0,4,48,8,8,1]]

Raw: ``0:0-7,48-55; 1:8-15,56-63; 2:16-23,64-71; 3:24-31,72-79``

**Cyclic distribution using repeat:**

Four values distributed across four keys in round-robin order::

    [[0,4,0,1,1,4]]

Raw: ``0:0,4,8,12; 1:1,5,9,13; 2:2,6,10,14; 3:3,7,11,15``

**Non-zero start:**

Three keys beginning at index 2::

    [[2,3,48,8,8,1]]

Raw: ``2:48-55; 3:56-63; 4:64-71``

**Single key, arbitrary base:**

One key receiving values 96-103::

    [[0,1,96,8,0,1]]

Raw: ``0:96-103``

**Graceful degradation under fragmentation:**

A regular mapping of 4 keys becomes fragmented when key 1 is
removed. The remaining keys 0, 2, and 3 require two blocks::

    [[0,1,0,8,0,1],[2,2,16,8,8,1]]

Raw: ``0:0-7; 2:16-23; 3:24-31``

**Unknown mapping:**

::

    []

Test Vectors
------------

The following table provides a compact reference for verifying
implementations. The raw idmap column uses ``key:idset`` pairs
separated by semicolons; spaces after semicolons are permitted
and SHOULD be ignored by parsers. Notes on selected vectors are
provided in the section below.

.. list-table::
   :header-rows: 1
   :widths: 3 42 55

   * - #
     - Raw idmap
     - Flux idmap
   * - 1
     - mapping unknown
     - ``[]``
   * - 2
     - ``0:0``
     - ``[[0,1,0,1,0,1]]``
   * - 3
     - ``0:0-7``
     - ``[[0,1,0,8,0,1]]``
   * - 4
     - ``0:0-1; 1:2-3``
     - ``[[0,2,0,2,2,1]]``
   * - 5
     - ``0:0-7; 1:8-15; 2:16-23; 3:24-31``
     - ``[[0,4,0,8,8,1]]``
   * - 6
     - ``0:100-107``
     - ``[[0,1,100,8,0,1]]``
   * - 7
     - ``0:0-7; 1:0-7``
     - ``[[0,2,0,8,0,1]]``
   * - 8
     - ``0:0-9; 1:5-14``
     - ``[[0,2,0,10,5,1]]``
   * - 9
     - ``0:0-7; 1:10-17``
     - ``[[0,2,0,8,10,1]]``
   * - 10
     - ``3:24-31``
     - ``[[3,1,24,8,0,1]]``
   * - 11
     - ``2:16-23; 3:24-31``
     - ``[[2,2,16,8,8,1]]``
   * - 12
     - ``0:0-3; 2:8-11; 4:16-19``
     - ``[[0,1,0,4,0,1],[2,1,8,4,0,1],[4,1,16,4,0,1]]``
   * - 13
     - ``1:0-3; 0:4-7``
     - ``[[1,1,0,4,0,1],[0,1,4,4,0,1]]``
   * - 14
     - ``0:0-3; 1:8-11; 2:16-19; 3:24-27; 4:4-7; 5:12-15; 6:20-23; 7:28-31``
     - ``[[0,4,0,4,8,2]]``
   * - 15
     - ``0:0-3; 1:4-7; 2:8-11; 3:12-15; 4:16-19; 5:20-23; 6:24-27; 7:28-31``
     - ``[[0,4,0,4,4,2]]``
   * - 16
     - ``0:0; 1:2; 2:4; 3:6``
     - ``[[0,4,0,1,2,1]]``
   * - 17
     - ``0:0,8; 1:1,9; 2:2,10; 3:3,11``
     - ``[[0,4,0,1,1,1],[0,4,8,1,1,1]]``
   * - 18
     - ``0:0-3; 1:4-7; 4:16-19; 5:20-23``
     - ``[[0,2,0,4,4,1],[4,2,16,4,4,1]]``
   * - 19
     - ``0:1000-1007; 1:1008-1015; 2:1016-1023``
     - ``[[0,3,1000,8,8,1]]``
   * - 20
     - ``0:0-3; 1:8-11; 2:4-7; 3:12-15``
     - ``[[0,1,0,4,0,1],[1,1,8,4,0,1],[2,1,4,4,0,1],[3,1,12,4,0,1]]``
   * - 21
     - ``0:0-7; 2:16-23; 3:24-31``
     - ``[[0,1,0,8,0,1],[2,2,16,8,8,1]]``
   * - 22
     - ``0:0,4,8,12; 1:1,5,9,13; 2:2,6,10,14; 3:3,7,11,15``
     - ``[[0,4,0,1,1,4]]``
   * - 23
     - ``0:0-7,48-55,96-103; 1:8-15,56-63,104-111; 2:16-23,64-71,112-119; 3:24-31,72-79,120-127``
     - ``[[0,4,0,8,8,1],[0,4,48,8,8,1],[0,4,96,8,8,1]]``

Notes on Test Vectors
---------------------

**Vector 1 — Unknown mapping.**
An empty array indicates the mapping is unknown. Implementations
MUST accept this as a valid idmap and MUST NOT treat it as an
error.

**Vector 2 — Single key, single value, stride irrelevant.**
The simplest non-empty case. With ``count=1``, the value of
``stride`` has no effect on the result and MUST be ignored by
implementations. Using ``stride=0`` is conventional for
single-key blocks.

**Vector 3 — Single key, size > 1.**
Confirms that ``size`` correctly determines the width of the
mapped range even when there is only one key.

**Vector 6 — Non-zero baseid.**
The mapped range need not start at zero. Implementations MUST
use ``baseid`` directly and MUST NOT assume a zero or computed
base.

**Vector 7 — Stride zero, multiple keys.**
When ``stride=0``, all keys map to the same value set. This is
valid. Implementations MUST NOT assume that value sets are
disjoint across keys.

**Vector 8 — Stride less than size (overlapping ranges).**
When ``stride < size``, consecutive keys have overlapping value
ranges. Key 0 maps to 0-9 and key 1 maps to 5-14, sharing
values 5-9. This is valid. Implementations MUST NOT clamp,
error, or deduplicate values in this case.

**Vector 9 — Stride greater than size (gap between keys).**
When ``stride > size``, there are values between consecutive
keys that belong to neither. This is the common case for
non-contiguous ID layouts where key-local ranges are separated
by a fixed offset larger than the per-key count.

**Vectors 10 and 11 — Non-zero start.**
The first key in a block need not be key 0. In vector 10 a
single key at index 3 is mapped. In vector 11 two consecutive
keys beginning at index 2 are mapped. Implementations MUST use
``start`` directly and MUST NOT assume blocks begin at key 0.

**Vector 12 — Non-contiguous key indices.**
Keys at indices 0, 2, and 4 are mapped with no entries at
indices 1 and 3. This requires three separate single-key
blocks. Implementations MUST NOT infer mappings for absent
keys.

**Vector 13 — Non-monotonic block order.**
Blocks need not appear in ascending order of ``start``. Key 1
is described before key 0. Implementations MUST NOT assume
blocks are sorted and MUST correctly assemble the mapping
regardless of block order.

**Vector 14 — Repeat with stride greater than size.**
``[[0,4,0,4,8,2]]`` expands to two repetitions. The first maps
keys 0-3 to values 0-3, 8-11, 16-19, 24-27 (baseid 0,
stride 8). The second repetition advances ``start`` by
``count=4`` and ``baseid`` by ``count*stride=32``, mapping
keys 4-7 to values 4-7, 12-15, 20-23, 28-31 (baseid 32,
stride 8). Implementations MUST advance both ``start`` and
``baseid`` correctly on each repetition.

**Vector 15 — Repeat with stride equal to size.**
``[[0,4,0,4,4,2]]`` tiles two consecutive blocks of four keys
forward in both key and value space. The first repetition maps
keys 0-3 to values 0-3, 4-7, 8-11, 12-15. The second
repetition advances ``baseid`` by ``count*stride=16``, mapping
keys 4-7 to values 16-19, 20-23, 24-27, 28-31.

**Vector 16 — Size 1, stride 2.**
Keys map to single values with a gap of one unused value
between each. Confirms that ``size=1`` and a non-unit stride
work correctly together.

**Vector 17 — Multiple blocks covering the same keys.**
Two blocks both cover keys 0-3, contributing different values.
The mapped value set for each key is the union of contributions
from all blocks. Implementations MUST correctly union value
sets from multiple blocks covering the same key.

**Vector 18 — Two disjoint blocks.**
Keys 0-1 and keys 4-5 are mapped by separate blocks with no
entry for keys 2-3. This illustrates graceful degradation: a
regular mapping that has become fragmented requires one block
per contiguous sub-range of keys, but no more, and the storage
cost never exceeds that of the raw idmap.

**Vector 19 — Large baseid.**
Confirms that implementations handle large base values
correctly and MUST NOT assume small or zero-based value spaces.

**Vector 20 — Non-ascending value order, taskmap equivalence.**
The value sets are not in ascending order relative to key
index, requiring four separate single-key blocks. This vector
also illustrates the equivalence relationship with RFC 34: the
RFC 34 taskmap block ``[0,4,4,1]`` maps to explicit idmap
blocks with baseid values derived from ``nodeid*ppn`` rather
than computed implicitly.

**Vector 21 — Graceful degradation under fragmentation.**
Key 1 from an originally regular 4-key mapping has been
removed. The remaining keys 0, 2, and 3 require two blocks.
Key 0 stands alone as a single-key block. Keys 2 and 3 form a
regular sub-pattern captured by a single 2-key block. Storage
cost increases in proportion to the number of distinct regular
sub-patterns, not the total number of keys, and never exceeds
the storage cost of the raw idmap.

**Vector 22 — Cyclic distribution using repeat.**
The repeat field compactly captures round-robin value
assignment. ``[[0,4,0,1,1,4]]`` performs 4 repetitions. In
each repetition ``r``, keys 0-3 each receive one additional
value, with baseid advancing by ``count*stride=4`` per
repetition. The result is that each key accumulates 4 values
spaced 4 apart.

**Vector 23 — Multi-die processor core mapping.**
Three blocks describe the complete core value mapping for a
processor with 4 dies, each containing 3 compute chiplets of
8 cores each. The non-contiguous physical core IDs arising
from the multi-die topology are captured as separate blocks,
one per contiguous sub-range, each covering all four dies in
a single compact 6-tuple. The storage cost is independent of
the number of dies.

.. _RFC 2119: https://tools.ietf.org/html/rfc2119
