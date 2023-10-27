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
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


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
dealing directly with these details, which are managed by the flux-core
*resource* module.

Version 1 of this protocol maps chunks of resources to integer *execution
targets*, and reports availability at the target level.  All resources are
mapped to targets, and all the resources associated with a given target are
either up or down as an atomic unit.  Execution targets map directly to
the *rank* idset under *R_lite* in the RFC 20 resource object *execution*
section.

A streaming ``resource.acquire`` RPC is offered by the flux-core resource
module to the scheduler.  The responses to this RPC define the resource
set available for scheduling, and mark targets *up* or *down* as
availability changes.

Version 1 of this protocol supports a static resource set per Flux instance.
Resource *grow* and *shrink* are to be handled by a future protocol revision.


Design Criteria
---------------

- Provide resource discovery service to scheduler implementations.

- Allow the scheduler to determine satisfiability of resource requests
  independent of resource availability.

- Support monitoring of available execution targets.

- Support administrative drain of execution targets.

- Support administrative exclusion of execution targets.


Implementation
--------------

The scheduler SHALL send a ``resource.acquire`` streaming RPC request at
initialization to obtain resources to be used for scheduling and monitor
changes in status.


Acquire Request
^^^^^^^^^^^^^^^

The ``resource.acquire`` request has no payload.


Initial Acquire Response
^^^^^^^^^^^^^^^^^^^^^^^^

The initial ``resource.acquire`` response SHALL include the following keys:

resources
  (object) RFC 20 (R version 1) resource object that contains the full resource
  inventory, less execution targets excluded by configuration.  The scheduler
  MAY use this set to determine the general satisfiability of job requests.

up
  (string) RFC 22 idset of execution targets in ``resources`` that are
  initially available.  The scheduler SHALL only allocate the resources
  associated with an execution target to jobs if the target is up.

Example:

.. code:: json

   {
      "resources": {
        "version": 1,
        "execution": {
          "R_lite": [
            {
              "rank": "0-5",
              "children": {
                "core": "0-5",
                "gpu": "0"
              }
            }
          ],
          "starttime": 0,
          "expiration": 0,
          "nodelist": [
            "host[0-5]"
          ]
        }
      },
      "up": "0-2"
   }


Additional Acquire Responses
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Subsequent ``resource.acquire`` responses SHALL include one or more
of the following OPTIONAL keys:

up
  (string) RFC 22 idset of execution targets that should be marked available
  for scheduling.  The idset only contains targets that are transitioning,
  not the full set of available targets.

down
  (string) RFC 22 idset of execution targets that should be marked unavailable
  for scheduling.  The idset only contains targets that are transitioning,
  not the full set of unavailable targets.

property-add
  (object) RFC 20 conforming properties object containing properties that
  should be added to the specified execution targets. When present, this
  key reflects an update to the instance resource inventory which MAY
  affect job satisfiability, the determination of which is left to the
  scheduler implementation.

property-remove
  (object) RFC 20 conforming properties object containing properties that
  should be removed from the specified execution targets. When present,
  this key reflects an update to the instance resource inventory which
  MAY affect job satisfiability, the determination of which is left to the
  scheduler implementation.

expiration
  (float) When present, this key notifies the scheduler that the expiration
  time of the resource set has been updated to the included floating-point
  value.

Example:

.. code:: json

   {
      "up": "3-6",
      "down": "2"
      "property-add": { "foo": "0-1" },
      "property-remove" { "bar": "3" }
   }

If down resources are assigned to a job, the scheduler SHALL NOT raise an
exception on the job.  The execution system takes the active role in handling
failures in this case.  Eventually the scheduler will receive a ``sched.free``
request for the offline resources.

.. note::
  *down* encompasses both crashed and drained execution targets.
  The scheduler handles both cases the same, so they are not differentiated
  in the protocol.

Error Response
^^^^^^^^^^^^^^

If an error response is returned to ``resource.acquire``, the scheduler
should log the error and exit the reactor, as failure indicates either a
catastrophic error, a failure to acquire any resources, or a failure to
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
  presumed that re-acquisition of resources will be accompanied by a
  ``job-manager.hello`` request, as described in RFC 27, to rediscover
  these allocations.
