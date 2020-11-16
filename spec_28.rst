.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_28.html

28/Flux Resource Acquisition Protocol Version 1
===============================================

This specification describes the Flux service that schedulers use to
acquire exclusive access to resources and monitor their ongoing
availability.

-  Name: github.com/flux-framework/rfc/spec_28.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`20/Resource Set Specification Version 1 <spec_20>`

-  :doc:`22/Idset String Representation <spec_22>`

-  :doc:`27/Flux Resource Allocation Protocol Version 1 <spec_27>`


Background
----------

A Flux instance manages a set of resources.  This resource set may be obtained
from a configuration file, dynamically discovered, or assigned by the enclosing
instance.  Resources may be excluded from scheduling by configuration, made
unavailable temporarily by administrative control, or fail unexpectedly.  The
resource acquisition protocol allows the scheduler to track the set of
resources available for scheduling and monitor ongoing availability, without
dealing directly with the details, which are managed by the flux-core
*resource* module.

Version 1 of this protocol maps chunks of resources to integer *execution
targets*, and reports availability at the target level.  All resources are
mapped to targets, and all the resources associated with a given target are
either up or down as an atomic unit.  Execution targets map directly to
the *rank* idset under *R_lite* in the RFC 20 resource object *execution*
section.

A streaming ``resource.acquire`` RPC is offered by the flux-core resource
module to the scheduler.  The responses to this RPC may dynamically *grow* or
*shrink* the resource set allocated to the scheduler, and mark targets
*online* or *offline* as availability changes.


Design Criteria
---------------

- Provide resource discovery service to scheduler implementations.

- Provide resource monitoring service to scheduler implementations.

- Allow the scheduler to determine satisfiability of resource requests
  independent of resource availability.

- Support administrative drain of execution targets.

- Support administrative exclusion of execution targets.


Implementation
--------------

The scheduler SHALL send a ``resource.acquire`` streaming RPC request at
initialization to obtain resources to be used for scheduling and monitor
changes in status.

There MAY be multiple active ``resource.acquire`` RPCs, should the scheduler
wish to acquire more than one resource group (see below).


Acquire Request
^^^^^^^^^^^^^^^

The ``resource.acquire`` request is a JSON object with the following
REQUIRED keys:

group
  (string) Resource group name or "default" to request all resources
  not assigned to any group

Example:

.. code:: json

   {
      "group": "default"
   }

.. note::
  In protocol version 1, the primary use case for groups is configuring
  an ``exclude`` group to keep login and service nodes out of the
  default group.

  In the future, groups may be used to define partitions
  or test resources.

Each response SHALL include the following key to designate the response type.

type
  (string) Response type: "grow", "shrink", "online", or "offline".

Each response type is described below.

Grow Response
^^^^^^^^^^^^^

The *grow* response adds resources to the scheduler.  In addition to
the ``type`` key described above, the response payload SHALL include
the following REQUIRED keys:

resources
  (object) RFC 20 (R version 1) resource object to add to the scheduler.

online
  (string) RFC 22 idset of execution targets in ``resources`` that are
  currently available.

offline
  (string) RFC 22 idset of execution targets in ``resources`` that are
  currently unavailable.

Example:

.. code:: json

   {
      "type": "grow",
      "resources": {
         "version": 1,
         "scheduling": {},
         "attributes": {},
         "execution": {
            "R_lite": {
               "rank": "1-6",
               "children": {}
	    }
         },
      },
      "online": "2-3",
      "offline": "1,4-6"
   }

The scheduler SHOULD wait until the first *grow* response to begin
evaluating whether job resource requests are satisfiable.

.. note::
  In protocol version 1, the primary use case for *grow* is group (exclusion)
  reconfiguration.

Shrink Response
^^^^^^^^^^^^^^^

The *shrink* response subtracts resources from the scheduler.  In addition to
the ``type`` key described above, the response payload SHALL include
the following REQUIRED keys:

targets
  (string) RFC 22 idset of execution targets to subtract from the scheduler.


Example:

.. code:: json

   {
      "type": "shrink",
      "targets": "2-3"
   }

The scheduler SHALL NOT allocate these resources to jobs in the future,
unless they are restored with a *grow* response.

If subtracted resources are already allocated to a job, the scheduler should
raise a fatal exception on the job.  The scheduler SHALL then be prepared
to process ``sched.free`` request(s) involving these resources.

As the subtracted resources become free, the scheduler SHALL send a
``resource.release`` request to the flux-core resource module (see below).

The scheduler SHOULD re-evaluate the satisfiability of all jobs in its
queue after receiving a *shrink* response.

.. note::
  In protocol version 1, the primary use case for *shrink* is group (exclusion)
  reconfiguration.

Online Response
^^^^^^^^^^^^^^^

The *online* response notifies the scheduler that resources that it previously
acquired have transitioned from *offline* to *online* state.  In addition to
the ``type`` key described above, the response payload SHALL include
the following REQUIRED keys:

targets
  (string) RFC 22 idset of execution targets to mark *online*.

Example:

.. code:: json

   {
      "type": "online",
      "targets": "2-3"
   }

Offline Response
^^^^^^^^^^^^^^^^

The *offline* response notifies the scheduler that resources that it previously
acquired have transitioned from *online* to *offline* state.  In addition to
the ``type`` key described above, the response payload SHALL include
the following REQUIRED keys:

targets
  (string) RFC 22 idset of execution targets to mark *offline*.

Example:

.. code:: json

   {
      "type": "offline",
      "targets": "2-3"
   }

The scheduler SHALL NOT allocate these resources to jobs in the future,
unless they are restored with an *online* response.

If offline resources are assigned to a job, the scheduler SHALL NOT
raise an exception on the job.  The execution system takes the
active role in handling failures in this case.  Eventually the scheduler
will receive a ``sched.free`` request for the offline resources.

.. note::
  *offline* encompasses both crashed and drained execution targets.
  The scheduler handles both cases the same, so they are not differentiated
  in the protocol.

Error Response
^^^^^^^^^^^^^^

If an error response is returned to ``resource.acquire``, the scheduler
should log the error and exit the reactor, as failure indicates either a
catastrophic error, a failure to acquire any resources, or a failure to
conform to this protocol.

Release Request
^^^^^^^^^^^^^^^

The scheduler SHALL send one or more ``resource.release`` requests to the
resource module to acknowledge *shrink* above, as the subtracted resources
become free.

The ``resource.release`` request is a JSON object with the following
REQUIRED keys:

group
  (string) Resource group name.

targets
  (string) RFC 22 idset of execution targets to release.

Example:

.. code:: json

   {
      "group": "default",
      "targets": "1-3,5"
   }

The *group* SHALL match the group used in the ``resource.acquire`` request.
The *targets* SHALL match, or be a proper subset of, the *shrink* targets.

The scheduler SHALL NOT send a ``resource.release`` request for execution
targets that were not previously included in *shrink*.

The release response SHALL have an empty payload.

In the event of an error response, the scheduler SHOULD log the error and exit
its reactor, as failure indicates either a catastrophic error or a failure to
conform to this protocol.

Disconnect Request
^^^^^^^^^^^^^^^^^^

If the scheduler is unloaded, a disconnect request is automatically sent to
the flux-core resource module.  This cancels the ``resource.acquire`` request
and makes resources available for re-acquisition.

Running jobs are unaffected.

.. note::
  This behavior on disconnect is intended to support reloading the
  scheduler on a live system without impacting the running workload.

  Since resources may remain allocated to jobs after a disconnect, it is
  presumed that re-acquisition of the same resource group will be accompanied
  by a ``job-manager.hello`` request, as described in RFC 27, to rediscover
  these allocations.
