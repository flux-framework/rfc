.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_40.html

40/Fluxion Resource Set Extension
#################################

This specification defines the data format used by the Fluxion scheduler
to store resource graph data in RFC 20 *R* version 1 objects.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_40.rst
  * - **Editor**
    - Dong H. Ahn <ahn1@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_4`
- :doc:`spec_14`
- :doc:`spec_20`
- :doc:`spec_27`
- :doc:`spec_28`

Background
**********

RFC 20 defines version 1 of Flux's JSON-based resource set representation *R*.
In version 1, resource types are purposefully constrained to nodes, cores, and
GPUs and there is no way to express a special relationship between nodes, or
between cores and GPUs within a node.  However, a ``scheduling`` key is defined
which allows scheduler-specific extensions to be attached to *R*, allowing more
complex resource types and relationships to be included, if only for the
benefit of the scheduler.

The ``scheduling`` key is opaque to rest of Flux, but:

- may be part of the static configuration of a Flux system instance
- passes through to the scheduler when it acquires its initial resource set
- passes through to jobs when resources are allocated to them
- passes through to Flux sub-instances for acquisition by their scheduler

This document describes the resource graph representation used by the Fluxion
scheduler within the ``scheduling`` key of *R*.

Implementation
**************

The Fluxion resource graph representation allows RFC4-compliant schedulers to
serialize any subset of graph resource data into its value and later
deserialize this value with no data loss. The ``scheduling`` key contains a
dictionary with a single key: ``graph``.  Other keys are reserved for future
extensions.  The ``graph`` key SHALL conform to the latest version of the JSON
Graph Format (JGF).  Thus, its value is a dictionary with two keys, ``nodes``
and ``edges``, that encode the resource vertices and edges as described in
RFC 4.

Graph Vertices
==============

The value of the ``nodes`` key defined in JGF is a strict list
of graph vertices. Each list member is a vertex that contains
two keys: ``id`` and ``metadata``.
The ``id`` key SHALL contain a unique string ID for the containing vertex.
The value of the ``metadata`` key is a dictionary that encodes
the resource pool data described in RFC 4.
Thus, this dictionary SHALL contain the following
keys to describe the base data of a resource pool:

-  ``type``

-  ``uuid``

-  ``basename``

-  ``name``

-  ``id``

-  ``properties``

-  ``size``

-  ``unit``

It MAY contain other OPTIONAL resource vertex data.

Graph Edges
===========

The value of the ``edges`` key defined in JGF SHALL be a strict list of graph edges.
Each list element SHALL be an edge that connects two graph vertices and
contains the ``source``, ``target`` and ``metadata`` keys.
The value of the ``source`` key SHALL contain the ID of the source graph vertex.
The value of the ``target`` key SHALL contain the ID of the target graph vertex.
The value of this ``metadata`` key SHALL contain a dictionary that encodes
the resource subsystem and relationship data for the containing edge
as described in RFC 4. It SHALL contain two keys:

**subsystem**
   The value of the ``subsystem`` key SHALL be a string that indicates
   a specific subsystem to which this edge belongs. (e.g., containment
   or power subsystems).

**relationship**
   The value of the ``relationship`` key SHALL be a string that indicates
   a relationship between the source and target resource vertices.
   The relationship SHALL only be defined within the subsystem defined
   above. (e.g., "contains" relationship within the "containment" subsystem).

References
**********

`JSON Graph Format Github, Anthony Bargnesi, et al., Visited Jan. 2019 <https://jsongraphformat.info>`__
