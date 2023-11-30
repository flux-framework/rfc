.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_34.html

34/Flux Task Map
################

The Flux Task Map is a compact mapping between job task ranks and node IDs.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_34.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_13`
- :doc:`spec_20`
- :doc:`spec_22`

Background
**********

The task map communicates how a parallel program's tasks are assigned to the
allocated nodes. Given a node ID, the task map can provide a set of ranks.
Given a rank, the task map can provide a node ID.  The task map has the
following uses:

- Inform parallel runtimes which tasks are co-located on a node so they can
  use local inter-process communication instead of the network.

- Assuming that the RFC 20 resource set (R) and the task map are part of the
  persistent job record, allow stderr tagged with a task ranks to be mapped to
  a node ID for postmortem correlation of job errors with node problems.

.. note::
  The task map does not communicate which tasks are bound to or contained with
  specific *resources* on the node such as cores or GPUs.

A task map can naively represented as a node ID-ordered list of RFC 22 idsets,
with each idset separated by a semicolon.  We use this format when defining
test vectors and refer to it as the *raw task map*.

Goals
*****

- Represent common regular task distributions such as *block* and *cyclic*
  in a space efficient manner so that the task map can be scalably
  communicated.

- Avoid the need for a custom parser.

- Allow custom mappings to be expressed.

Existing Implementations
************************

A de-facto standard task map format is the PMI-1 ``PMI_process_mapping`` format
described in RFC 13, which specifies a list of *map blocks*, each a 3-tuple
of (*nodeid*, *nnodes*, *ppn*).  Some examples are:

.. list-table:: PMI task maps with regular task distribution
   :header-rows: 1

   * - nnodes*ppn
     - block
     - cyclic:1
     - cyclic:2
   * - 4*4
     - (vector,(0,4,4))
     - (vector,(0,4,1),(0,4,1),(0,4,1),(0,4,1))
     - (vector,(0,4,2),(0,4,2))
   * - 4*2 + 2*4
     - (vector,(0,4,2),(4,2,4))
     - (vector,(0,6,1),(0,6,1),(4,2,1),(4,2,1))
     - (vector,(0,6,2),(4,2,2))
   * - 4096*256
     - (vector,(0,4096,256))
     - *long (256 map blocks)*
     - *long (128 map blocks)*

.. note::
  The cyclic:N distribution for N > 1 is equivalent to Slurm's *plane*
  distribution.

This mapping is compact for *block* task distributions, where blocks of
contiguous task ranks are assigned to nodes in ascending order.  Its
scalability breaks down for *cyclic* task distributions, where one or more
task ranks are assigned to nodes in round-robin order. As an example, a PMI
task map for 1M tasks distributed over 4K nodes in block distribution is
compact as shown above, but the same job with a cyclic distribution (stride
of 1) is a string of 2824 characters.

Implementation
**************

The Flux task map SHALL be represented as a JSON array to avoid the need
for a custom parser.  The array MUST contain zero or more *map blocks*.

A Flux task map that contains zero map blocks SHALL indicate that the task
mapping is unknown.

A Flux task map block is a JSON array with four REQUIRED integer array
elements:

nodeid
  The starting node ID for the block (zero-origin).

nnodes
  The number of nodes represented by the block.

ppn
  The number of tasks per node in the block.

repeat
  The number of times the map block is logically repeated.

.. note::
  The Flux 4-tuple map block is a superset of the 3-tuple employed by PMI.
  Flux adds the *repeat* element so that map blocks need not be explicitly
  repeated in cyclic distributions.

The following table provides simple examples of Flux task maps
for common regular task distributions:

.. list-table:: Flux task maps with regular task distribution
   :header-rows: 1

   * - nnodes*ppn
     - block
     - cyclic:1
     - cyclic:2
   * - 4*4
     - [[0,4,4,1]]
     - [[0,4,1,4]]
     - [[0,4,2,2]]
   * - 4*2 + 2*4
     - [[0,4,2,1],[4,2,4,1]]
     - [[0,6,1,2],[4,2,1,2]]
     - [[0,6,2,1],[4,2,2,1]]
   * - 4096*256
     - [[0,4096,256,1]]
     - [[0,4096,1,256]]
     - [[0,4096,2,128]]

The Flux task map MAY be wrapped in a JSON object when it is communicated.
The JSON object has the following REQUIRED keys:

version
  The integer task map version (1 for this RFC).

map
  The task map array described above.

Example:

.. code:: json

  {"version":1, "map":[[0,4096,256,1]]}

Test Vectors
************

.. list-table::
   :header-rows: 1

   * - raw task map
     - Flux task map
   * - mapping unknown
     - []
   * - 0
     - [[0,1,1,1]]
   * - 0;1
     - [[0,2,1,1]]
   * - 0-1
     - [[0,1,2,1]]
   * - 0-1;2-3
     - [[0,2,2,1]]
   * - 0,2;1,3
     - [[0,2,1,2]]
   * - 1;0
     - [[1,1,1,1],[0,1,1,1]]
   * - 0-3;4-7;8-11;12-15
     - [[0,4,4,1]]
   * - 0,4,8,12;1,5,9,13;2,6,10,14;3,7,11,15
     - [[0,4,1,4]]
   * - 0-1,8-9;2-3,10-11;4-5,12-13;6-7,14-15
     - [[0,4,2,2]]
   * - 0-1;2-3;4-5;6-7;8-11;12-15
     - [[0,4,2,1],[4,2,4,1]]
   * - 0,6;1,7;2,8;3,9;4,10,12,14;5,11,13,15
     - [[0,6,1,2],[4,2,1,2]]
   * - 14-15;12-13;10-11;8-9;4-7;0-3
     - [[5,1,4,1],[4,1,4,1],[3,1,2,1],[2,1,2,1],[1,1,2,1],[0,1,2,1]]
   * - 0-1;2-3;4-5;6-7;8-9;12-13;10-11;14-15
     - [[0,5,2,1],[6,1,2,1],[5,1,2,1],[7,1,2,1]]
   * - 12-15;8-11;4-7;0-3
     - [[3,1,4,1],[2,1,4,1],[1,1,4,1],[0,1,4,1]]
