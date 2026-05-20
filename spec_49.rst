.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_49.html

49/TreePool Resource Set Extension
###################################

This specification defines the format of the scheduling key used by the
TreePool scheduler to encode sub-node topology in RFC 20 *R* version 1
objects.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_49.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_14`
- :doc:`spec_20`
- :doc:`spec_22`
- :doc:`spec_40`
- :doc:`spec_46`

Background
**********

RFC 20 defines a scheduling key in *R* version 1 for scheduler-specific
extensions.  RFC 40 uses this key for the Fluxion graph scheduler.  This RFC
defines a complementary format for the TreePool scheduler.

The base Rv1 format is intentionally flat: it lists nodes and their resource
counts but carries no topology.  Fluxion (RFC 40) represents topology as an
arbitrary graph, enabling rich scheduling at the cost of complexity and large
*R* objects.  This format occupies the middle ground: it encodes topology as
trees rather than arbitrary graphs, which is sufficient for simple locality
aware scheduling at the node level, while keeping *R* objects compact and
easy to generate.

This RFC extends the base Rv1 object with sub-node topology describing how
cores, GPUs, memory, and storage are grouped within a node (e.g. by NUMA
domain or socket), enabling affinity-aware allocation of co-located resources.
Super-node grouping (rack, chassis) is not covered by this specification.

Implementation
**************

.. describe:: scheduling

  (*dictionary*, OPTIONAL) The scheduling key as defined in RFC 20 SHALL
  contain the following keys when this specification is used:

  .. describe:: writer

    (*string*, REQUIRED) SHALL be set to "TreePool".  Schedulers use this
    value to select the TreePool pool class automatically.

  .. describe:: children

    (*array of object*, OPTIONAL) Sub-node topology.  Each object SHALL
    contain exactly two structural keys:

    .. describe:: ranks

      (*string*, REQUIRED) An RFC 22 idset string identifying the broker
      ranks that share the described node topology.

    .. describe:: topo

      (*object*, REQUIRED) The node topology object.  This is a recursive
      structure of locality domains.  Each locality domain is represented as
      a key whose value is an array of child domain objects.  Only levels
      meaningful to the topology need be included; levels that carry no
      useful grouping information MAY be omitted.

      Defined locality names within *topo*:

      .. describe:: socket

        A processor package.  On multi-socket systems this groups the cores
        and GPUs physically attached to one socket.

      .. describe:: numa

        A NUMA memory domain.

      Other locality names MAY be used for site-specific topologies.

      Locality names defined in *topo* MAY be used as resource vertex types
      in RFC 14 jobspecs.  When such a vertex is marked exclusive with no
      child resources, the TreePool scheduler SHALL allocate all resources
      within that topology domain; per-domain resource counts are determined
      from *topo* at scheduling time.

      The following resource keys MAY appear in a locality domain object or
      directly in *topo* (at node scope) to describe resources local to that
      domain:

      .. describe:: cores

        (*string*) An RFC 22 idset string of node-local core IDs.

      .. describe:: gpus

        (*string*) An RFC 22 idset string of node-local GPU IDs.

      .. describe:: memory

        (*integer*) GiB of memory local to this domain.

      .. describe:: storage

        (*array of object*) Storage local to this domain.  This key SHOULD
        appear only at node scope (directly in *topo*).  Each object SHALL
        contain:

        .. describe:: path

          (*string*, REQUIRED) Mount point or logical identifier for the
          storage.

        .. describe:: capacity

          (*number*, REQUIRED) Numeric capacity value.

        .. describe:: unit

          (*string*, OPTIONAL) Unit string as defined in RFC 14
          (e.g. "GiB", "TiB").  Default is "GiB".

    Ranks with identical node topology MAY share a single *children* entry.

Key Summary
===========

.. list-table::
  :widths: 15 20 25 40
  :header-rows: 1

  * - Key
    - Key Type
    - HWLOC Type
    - Description
  * - *topo*
    - structural key
    - HWLOC_OBJ_MACHINE
    - Node topology object; peer of *ranks* in each children entry
  * - *socket*
    - locality name
    - HWLOC_OBJ_PACKAGE
    - A processor package
  * - *numa*
    - locality name
    - HWLOC_OBJ_NUMANODE
    - A NUMA memory domain
  * - *memory*
    - resource key
    - HWLOC_OBJ_NUMANODE
    - GiB of memory local to this domain
  * - *cores*
    - resource key
    - HWLOC_OBJ_CORE
    - core IDs
  * - *gpus*
    - resource key
    - HWLOC_OBJ_OSDEV_GPU
    - GPU IDs
  * - *storage*
    - resource key
    -
    - Storage device or mount point (node scope only)

Other locality names MAY be used for site-specific topologies.

Allocated R
===========

When resources are allocated, the scheduling key of the allocated *R* SHALL
be updated as follows and stored in the KVS job schema with parent-relative
rank values:

- *children* entries: the *ranks* value is trimmed to the intersection with
  the allocated rank set.  Entries with no allocated ranks are removed.

The *topo* structure within each surviving *children* entry is carried through
unchanged; it describes the full physical topology of the node, not the
allocated subset.  The authoritative record of which specific cores and GPUs
are allocated is the Rv1 *R_lite* ``children`` idsets.  The *memory* and
*storage* keys are capacity hints that inform scheduler placement decisions
but are not tracked per-job in the Rv1 record.  The scheduling key serves as
a topology hint for the sub-instance scheduler, enabling affinity-aware
placement within the allocated node set.

Sub-instance Initialization
----------------------------

When allocated *R* is used to initialize a sub-instance scheduler, rank
values in *children* entries SHALL be normalized to zero-origin, mapping
each parent rank to its zero-based position within the allocated rank set
ordered numerically.  This normalization mirrors the transformation already
applied to the Rv1 *R_lite* ranks during sub-instance startup.

Test Vectors
************

The following examples define two representative cluster topologies and
illustrate how resource requests are fulfilled by the TreePool scheduler.

Test vector tables map RFC 46 job shapes to the expected Rv1 *R_lite*
allocation.  Allocations are cumulative: each row assumes all prior
rows in the table are already in place.  Best-fit node selection is assumed.

Cluster A: Xeon/Nvidia Cluster
==============================

A 16-node cluster modeled on a dual-socket Intel Xeon system (e.g. Dell
PowerEdge XE9680) with Sub-NUMA Clustering (SNC4) enabled.  Each node has
two sockets of four NUMA domains, 15 cores and one NVIDIA GPU per NUMA
domain (8 GPUs per node, 120 cores per node), and a 2 TiB node-local NVMe
device.

.. code-block:: json

   {
     "writer": "TreePool",
     "children": [
       {
         "ranks": "0-15",
         "topo": {
           "storage": [{"path": "/mnt/nvme", "capacity": 2, "unit": "TiB"}],
           "socket": [
             {"numa": [
               {"cores": "0-14",    "gpus": "0"},
               {"cores": "15-29",   "gpus": "1"},
               {"cores": "30-44",   "gpus": "2"},
               {"cores": "45-59",   "gpus": "3"}
             ]},
             {"numa": [
               {"cores": "60-74",   "gpus": "4"},
               {"cores": "75-89",   "gpus": "5"},
               {"cores": "90-104",  "gpus": "6"},
               {"cores": "105-119", "gpus": "7"}
             ]}
           ]
         }
       }
     ]
   }

.. list-table::
  :widths: 5 38 57
  :header-rows: 1

  * - ID
    - Job Shape
    - *R_lite*
  * - TVA1
    - slot=1/node=1/[core=8;gpu=1]
    - {"rank": "0", "children": {"core": "0-7", "gpu": "0"}}
  * - TVA2
    - slot=1/node=1/[core=8;gpu=1]
    - {"rank": "0", "children": {"core": "15-22", "gpu": "1"}}
  * - TVA3
    - node/slot=8/[core=15;gpu=1]
    - {"rank": "1", "children": {"core": "0-119", "gpu": "0-7"}}
  * - TVA4
    - slot=4/node/core=120
    - {"rank": "2-5", "children": {"core": "0-119"}}
  * - TVA5
    - slot=1/node=1/core=4
    - {"rank": "0", "children": {"core": "8-11"}}
  * - TVA6
    - slot=1/node=1/[core=15;gpu=1]
    - {"rank": "0", "children": {"core": "30-44", "gpu": "2"}}
  * - TVA7
    - node/slot=6/[core=15;gpu=1]
    - {"rank": "6", "children": {"core": "0-89", "gpu": "0-5"}}
  * - TVA8
    - slot=1/node=1/[core=60;gpu=4]
    - {"rank": "0", "children": {"core": "60-119", "gpu": "4-7"}}
  * - TVA9
    - slot=1/numa{x}
    - {"rank": "0", "children": {"core": "45-59", "gpu": "3"}}
  * - TVA10
    - slot=1/socket{x}
    - {"rank": "7", "children": {"core": "0-59", "gpu": "0-3"}}
  * - TVA11
    - slot=1/node{x}
    - {"rank": "8", "children": {"core": "0-119", "gpu": "0-7"}}

- **TVA2**: After TVA1, NUMA 0 has 7 free cores but GPU 0 is gone.  A slot
  requires cores and GPU from the same NUMA domain, so the allocator skips
  NUMA 0 and takes cores 15–22 and GPU 1 from NUMA 1 on the same node.
- **TVA3**: Rank 0 has only 6 full NUMA domains after TVA1–2.  The 8-slot job
  needs 8, so the allocator skips rank 0 and uses rank 1.
- **TVA4**: Rank 0 is fragmented; rank 1 was fully consumed by TVA3.
- **TVA5**: CPU-only best-fit selects rank 0 (104 free cores) over a fresh node
  (120 free cores); within rank 0 the first NUMA with ≥ 4 free cores is
  NUMA 0 (cores 8–14), yielding cores 8–11.
- **TVA6**: TVA5 reduced NUMA 0 to 3 free cores; NUMA 1 has no free GPU.  The
  first NUMA on rank 0 with both 15 free cores and a free GPU is NUMA 2
  (cores 30–44, GPU 2).
- **TVA7**: After TVA6, rank 0 has only 5 intact NUMAs (3–7); the 6-slot
  request needs 6, so it advances to rank 6.
- **TVA8**: A 60-core/4-GPU slot fits exactly one socket (4 NUMAs × 15 cores).
  Rank 0's socket 1 (NUMAs 4–7, cores 60–119, GPUs 4–7) is still intact and
  beats a fully-free node (85 vs. 120 free cores) under best-fit scoring.
- **TVA9**: After TVA8, rank 0 has 25 free cores; NUMA 3 (cores 45–59, GPU 3)
  is the only intact NUMA domain remaining on rank 0.  Best-fit selects
  rank 0 over rank 6 (30 free cores) and fresh nodes (120 free cores); the
  exclusive NUMA slot claims all resources in that domain.
- **TVA10**: After TVA9, rank 0 has 10 free cores but no intact NUMA or socket.
  Rank 6 has two intact NUMAs (6–7) but both of its sockets span used and
  free NUMAs, so neither socket is fully free.  Rank 7 is the first node
  with an intact socket; socket 0 (NUMAs 0–3, cores 0–59, GPUs 0–3) is
  selected.
- **TVA11**: After TVA10, rank 7 is partially used (socket 0 claimed); ranks
  0–7 all have some resources allocated so none qualifies as fully free.
  Rank 8 is the first fully-free node.  No core constraint is specified;
  node-exclusive allocation claims all 120 cores and 8 GPUs.

Cluster B: HPE Cray EX Cluster
==============================

A 1152-node HPE Cray EX system (ranks 0–1151) in which each node is equipped
with four AMD Instinct MI300A APUs.  Each MI300A presents to the OS as a CPU
package with one NUMA node of HBM, 24 cores, and one GPU; memory varies
slightly due to firmware reservation (package 0: 125 GiB, packages 1–3:
126 GiB each).  A 200 GiB per-node burst-buffer allocation is pre-mounted
at ``/l/ssd``.

.. code-block:: json

   {
     "writer": "TreePool",
     "children": [
       {
         "ranks": "0-1151",
         "topo": {
           "storage": [{"path": "/l/ssd", "capacity": 200, "unit": "GiB"}],
           "socket": [
             {"cores": "0-23",  "gpus": "0", "memory": 125},
             {"cores": "24-47", "gpus": "1", "memory": 126},
             {"cores": "48-71", "gpus": "2", "memory": 126},
             {"cores": "72-95", "gpus": "3", "memory": 126}
           ]
         }
       }
     ]
   }

.. list-table::
  :widths: 5 38 57
  :header-rows: 1

  * - ID
    - Job Shape
    - *R_lite* entry
  * - TVB1
    - slot=1/node=1/[core=24;gpu=1]
    - {"rank": "0", "children": {"core": "0-23", "gpu": "0"}}
  * - TVB2
    - slot=1/node=1/[core=24;gpu=1]
    - {"rank": "0", "children": {"core": "24-47", "gpu": "1"}}
  * - TVB3
    - node/slot=4/[core=24;gpu=1]
    - {"rank": "1", "children": {"core": "0-95", "gpu": "0-3"}}
  * - TVB4
    - slot=4/node/[core=96;gpu=4]
    - {"rank": "2-5", "children": {"core": "0-95", "gpu": "0-3"}}
  * - TVB5
    - slot=1/node=1/core=8
    - {"rank": "0", "children": {"core": "48-55"}}
  * - TVB6
    - slot=1/node=1/[core=24;gpu=1]
    - {"rank": "0", "children": {"core": "72-95", "gpu": "3"}}
  * - TVB7
    - node/slot=3/[core=24;gpu=1]
    - {"rank": "6", "children": {"core": "0-71", "gpu": "0-2"}}
  * - TVB8
    - slot=1/socket{x}
    - {"rank": "6", "children": {"core": "72-95", "gpu": "3"}}
  * - TVB9
    - slot=1/node{x}
    - {"rank": "7", "children": {"core": "0-95", "gpu": "0-3"}}

- **TVB2**: After TVB1, package 0 is fully consumed.  The second slot takes
  package 1 on the same node.
- **TVB3**: Rank 0 has only 2 free packages after TVB1–2.  The 4-slot job needs
  4, so the allocator skips rank 0 and uses rank 1.
- **TVB4**: Rank 0 is fragmented; rank 1 was fully consumed by TVB3.
- **TVB5**: CPU-only best-fit selects rank 0 (48 free cores) over a fresh node
  (96 free cores); the first free package is package 2 (cores 48–71),
  yielding cores 48–55.
- **TVB6**: TVB5 consumed 8 cores from package 2, leaving only 16 free there.
  Package 3 remains intact with 24 cores and GPU 3.
- **TVB7**: After TVB6, rank 0 has no intact packages; the 3-slot request
  advances to rank 6.
- **TVB8**: After TVB7, rank 6 has one intact socket remaining (socket 3,
  cores 72–95 and GPU 3).  Best-fit selects rank 6 (24 free cores) over a
  fully-free node (96 free cores); the exclusive socket slot claims all
  resources in that domain.
- **TVB9**: After TVB8, rank 6 is fully consumed (all four sockets taken by
  TVB7 and TVB8).  Rank 7 is the first fully-free node.  No core constraint
  is specified; node-exclusive allocation claims all 96 cores and 4 GPUs.
