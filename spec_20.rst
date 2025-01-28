.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_20.html

.. default-domain:: js

20/Resource Set Specification Version 1
#######################################

This specification defines the version 1 format of the resource-set
representation or *R* in short.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_20.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_4`
- :doc:`spec_14`
- :doc:`spec_15`
- :doc:`spec_16`
- :doc:`spec_22`
- :doc:`spec_29`
- :doc:`spec_31`

Overview
********

This specification describes a JSON object *R* used to represents sets of
specific resources.  *R* is for representing concrete resources like "cores
2-5 of node 9".  It is distinct from the *jobspec* resources section (RFC 14)
which is for abstract resource requirements like "one node with four cores".

The following Flux subsystems must handle *R*:

resource module
  A Flux instance has a resource inventory which it obtains from configuration,
  through allocation from the enclosing instance, or via dynamic probing.
  The end result is expressed as *R*.  The resources in *R* are also monitored
  at the rank level for availability.

scheduler
  The scheduler obtains the resource inventory at initialization and fulfills
  job requests by allocating *R* subsets to them.  When jobs terminate their
  *R* subsets are returned to the scheduler and become available for
  fulfilling other job requests.

job manager
  The job manager tracks *R* so it can pass it to the scheduler and execution
  subsystems as the job transitions through job states.  In addition, *R* is
  made available to jobtap plugins which extend the job manager's function.
  Finally, when *R* is updated, for example to extend the duration of a
  running job, the job manager coordinates *R* updates across subsystems.

execution
  The job execution system uses *R* to determine where to launch Flux shells.

shell
  The job shell uses *R* to determine where to launch tasks.  Shell plugins
  may use *R* for various purposes such setting core and GPU affinity.

Design Goals
************

*R* is designed with the following goals:

-  Identify the specific resources where a job's tasks are to be launched.

-  Identify the specific resources managed by a Flux instance.

-  Be suitable for inclusion in a job's post-mortem record, and useful for
   answering forensic questions like "did my job run on the node that failed?".

-  Handle nodes, cores, and GPUs simply to ease the initial Flux implementation.

-  Allow schedulers to add proprietary enhancements that are ignored by
   the rest of Flux.

-  Don't explode in size on large clusters/jobs.

-  Handle resource properties as described in RFC 31

-  Build towards the general resource model of RFC 4.

Implementation
**************

.. note::

  In Flux documentation, the terms "node rank" and "execution target" are
  sometimes used interchangeably to refer to the Flux broker rank used to
  launch tasks on a given resource set.  When Flux launches a new Flux
  instance on a subset of resources, the new broker ranks do not match those
  of the the enclosing instance and the inherited *R* must be re-ranked
  before it can be brought into inventory.  Therefore, to avoid implying
  that a node rank uniquely identifies a physical node across instances,
  execution target is preferred in this document.

R Format
========

*R* SHALL be defined as a JSON dictionary with the following keys:

.. data:: version

  (*integer*, REQUIRED) The *R* specification version.

  For this specification the value is always 1.

.. data:: execution

  (*dictionary*, REQUIRED) The resource set.  It SHALL have following keys:

  .. data:: R_lite

    (*array of dictionary*, REQUIRED) A list that identifies one or more
    execution targets and the specific cores and GPUs they control.
    The list entries need not appear in any particular order.  Each entry
    SHALL have the following keys:

    .. data:: rank

      (*string*, REQUIRED) An RFC 22 idset representing one or more execution
      targets.

    .. data:: children

      (*dictionary*, REQUIRED) The specific resources controlled by the
      execution targets in :data:`rank`.  It SHALL have the following keys:

      .. data:: core

        (*string*, REQUIRED) An RFC 22 idset representing one or more
	logical CPU cores IDs.

      .. data:: gpu

        (*string*, OPTIONAL) An RFC 22 idset representing one or more
	logical GPU IDs.

  .. data:: nodelist

    (*array of string*, REQUIRED) A list of hostnames corresponding
    to the execution targets in :data:`R_lite`.

    Each entry SHALL be either a single hostname or an RFC 29 hostlist.

    The order of hostnames MUST correspond to the sorted list of execution
    targets ranks in :data:`R_lite` so that they can be mapped one to one.
    However, the number of entries in each array need not be
    the same.  For example, :data:`nodelist` MAY contain one hostlist entry
    for all the execution targets spread over multiple :data:`R_lite` entries.

  .. data:: properties

    (*dictionary of string*, OPTIONAL) Each key
    maps a single property name to a RFC 22 idset string. The idset string
    SHALL represent a set of execution targets. A given target MAY appear in
    multiple property mappings. Property names SHALL be valid UTF-8, and MUST
    NOT contain the following illegal characters::

      ! & ' " ^ ` | ( )

    Additionally, the ``@`` character is reserved for scheduler specific
    property use. In this case, the literal property SHALL still apply
    to the defined execution target ranks, but the scheduler MAY use the
    suffix after ``@`` to apply the property to children resources of the
    execution target or for another scheduler specific purpose. For example,
    the property ``amd-mi50@gpu`` SHALL apply to the defined execution
    target ranks, but a scheduler MAY use the ``gpu`` suffix to perform
    scheduling optimization for gpus of the corresponding ranks. This MAY
    result in both ``amd-mi50@gpu`` and ``amd-mi50`` being valid properties
    for resources in the instance.

  .. data:: starttime

    (*number*, OPTIONAL) The start time at which the resource set is valid.

    A value of `0.` SHALL be interpreted as "unset".

    The value SHALL be expressed as the number of seconds elapsed since the
    Unix Epoch (1970-01-01 00:00:00 UTC) with optional microsecond precision.

    If :data:`starttime` is unset, then the resource set has no specified
    start time and is valid beginning at any time up to :data:`expiration`.

  .. data:: expiration

    (*number*, OPTIONAL) The end or expiration time of the resource set,
    after which it becomes invalid.

    A value of `0.` SHALL be interpreted as "unset".

    The value SHALL be expressed as the number of seconds elapsed since the
    Unix Epoch (1970-01-01 00:00:00 UTC) with optional microsecond precision.

    If :data:`starttime` is also set, :data:`expiration` MUST be greater than
    :data:`starttime`.

    If :data:`expiration` is unset, the resource set has no specified end time.

.. data:: scheduling

  (*dictionary*, OPTIONAL) Scheduler-specific resource data which SHOULD NOT
  be interpreted other Flux components.  When used, it SHALL ride along on the
  resource acquisition protocol (RFC 28) and resource allocation protocol
  (RFC 27) so that it may be included in static configuration, allocated to
  jobs, and passed down a Flux instance hierarchy.

  Linkage to specific resources in :data:`R_lite` SHOULD use hostnames rather
  than execution targets since the scheduler-agnostic re-ranking of *R* that
  occurs when a new Flux instance is started cannot do the same for the opaque
  :data:`scheduling` key.

.. data:: attributes

  The purpose of the :data:`attributes` key is to provide optional
  information on this *R* document. The :data:`attributes` key SHALL
  be a dictionary of one key: :data:`system`.

  Other keys are reserved for future extensions.

  .. data:: system

    Attributes in the :data:`system` dictionary provide additional system
    information that have affected the creation of this *R* document.
    All of the system attributes are optional.

    A common system attribute is:

    .. describe:: scheduler

      The value of the :data:`scheduler` key is a free-from dictionary that
      may provide the information specific to the scheduler used
      to produce this document. For example, a scheduler that
      manages multiple job queues may add ``queue=batch``
      to indicate that this resource set was allocated from within
      its ``batch`` queue.

Example R
=========

The following is an example of a version 1 resource specification.
The example below indicates a resource set with the ranks 19
through 22.  These ranks correspond to the nodes node186 through
node189.  Each of the nodes contains 48 cores (0-47) and 8 gpus (0-7).
The :data:`starttime` and :data:`expiration` indicate the resources were valid
for about 30 minutes on February 16, 2023.

.. literalinclude:: data/spec_20/example1.json
   :language: json

