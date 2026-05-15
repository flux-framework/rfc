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

Topology levels are anonymous containers — they carry no numeric ID and are
identified only by their position in the hierarchy and the set of broker ranks
they apply to.  Resources that require specific device assignment (*cores*,
*gpus*) are identified by RFC 22 idset strings within a locality domain.

The *children* key extends the base Rv1 object with sub-node topology
describing how cores, GPUs, memory, and storage are grouped within a node
(e.g. by NUMA domain or socket), enabling affinity-aware allocation of
co-located resources.  Super-node grouping (rack, chassis) is not covered
by this specification.

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
      meaningful to the topology need be included.

      **Single-element collapse**: when a locality domain array contains
      exactly one element, that level is omitted and the element's fields are
      merged directly into the parent object.  This rule applies recursively,
      so a single-socket node with a single NUMA domain per socket produces a
      flat ``topo`` object with only resource keys.

      Defined locality names within *topo*:

      .. describe:: socket

        A processor package.  On multi-socket systems this groups the cores
        and GPUs physically attached to one socket.

      .. describe:: numa

        A NUMA memory domain.

      Other locality names MAY be used for site-specific topologies.

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

Sub-instance Initialization
----------------------------

When allocated *R* is used to initialize a sub-instance scheduler, rank
values in *children* entries SHALL be normalized to zero-origin, mapping
each parent rank to its zero-based position within the allocated rank set
ordered numerically.  This normalization mirrors the transformation already
applied to the Rv1 *R_lite* ranks during sub-instance startup.

Use Cases
*********

The following examples define two representative cluster configurations and
illustrate how various job shapes interact with the scheduling key.

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
  :widths: 38 25 37
  :header-rows: 1

  * - Job Shape
    - Goal
    - Scheduler Behavior
  * - slot=1/node=1/[core=8;gpu=1]
    - GPU job with affinity
    - Core set and GPU allocated from the same NUMA domain
  * - slot=8/node=1/[core=15;gpu=1]
    - Fill all GPUs on one node
    - Each GPU+core slot lands in a distinct NUMA domain
  * - slot=1/node=4/core=120
    - CPU-only job, full nodes
    - 4 nodes allocated; no GPU or NUMA constraint applied
  * - slot=1/node=4/[core=4;storage=500]
    - Node-local NVMe scratch
    - 500 GiB of ``/mnt/nvme`` reserved per node on 4 nodes

Cluster B: HPE Cray EX / AMD MI300A Cluster
===========================================

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
  :widths: 46 24 30
  :header-rows: 1

  * - Job Shape
    - Goal
    - Scheduler Behavior
  * - slot=1/node=1/[core=24;gpu=1]
    - Single MI300A GPU+core slot
    - 24 cores and GPU allocated from the same package
  * - slot=4/node=1/[core=24;gpu=1]
    - All four MI300As on one node
    - Each slot from a distinct package; GPU+core co-located within each
  * - slot=1/node=64/core=24
    - Large CPU job
    - 64 nodes allocated; NUMA constraint not applied (no GPU requested)
  * - slot=1/node=1/socket{x}/[core=24;gpu=1]
    - Exclusive APU
    - Full MI300A package reserved; 24 cores and GPU co-located within it
  * - slot=1/node=4/[core=24;gpu=1;storage=50]
    - GPU job with burst-buffer scratch
    - GPU+core NUMA-local; 50 GiB of ``/l/ssd`` reserved per node
