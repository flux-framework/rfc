51/Flux Resource Allocation Protocol Extensions
################################################

This specification describes optional extensions of the Flux Resource Allocation Protocol Version 1 (RFC 27).

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec\_51.rst
  * - **Editor**
    - Dominik Huber \<domi.huber\@tum.de>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_3`
- :doc:`spec_14`
- :doc:`spec_16`
- :doc:`spec_20`
- :doc:`spec_21`
- :doc:`spec_23`
- :doc:`spec_25`
- :doc:`spec_27`

Background
**********

Flux Resource Allocation Protocol Version 1 (RFC 27) describes scheduler 
RPCs for **static** resource allocation.
This RFC describes optional extensions to support **dynamic** resource 
allocations.

Dynamic Resource Management (DRM) allows dynamic changes to a job's resource 
allocation during runtime.
Such changes are achieved through **dynamic reallocation operations**, 
(i.e. modifications of the Flux Resource Set such as adding and/or removing 
resources).
To coordinate such dynamic reallocation operations, a communication mechanism 
between jobs and schedulers involving the shell and job manager is required.

This covers both, malleable and evolving jobs, through a unified mechanism.

The communication mechanism defined in this RFC is based on the 
``PMIx_Allocation_request`` [#f1]_ and is therefore not supported by the PMI-1 
wire protocol.

Conceptually, the envisioned mechanism consists of these steps:

1. **Dynamic allocation request:** Jobs indicate support for dynamic 
reallocation operations towards the scheduler. For simplicity, we refer to 
this as **dynamic allocation request**, although it more generally 
describes **a space of possible reallocation actions** supported by the 
job (e.g. supported range of number of resources, supported resource types, 
...) **coupled with optimization information** (e.g. performance models, 
urgency, ...).

.. note::

  TODO: The representation of optimization information might be specified in a 
  separate RFC

2. **Dynamic allocation response:** The scheduler eventually responds with
a concrete reconfiguration decision towards jobs, which lies within the 
constraints specified in the request.

3. **Resource release**: Resource release requires an additional step, in 
which jobs explicitly release resources back to the system.

While this RFC focuses on the interaction between job manager and scheduler, 
DRM also requires interactions between jobs, the shell, and the job manager.
Therefore, in the following paragraph we provide broader context of the realization 
of **dynamic reallocation operations** within Flux.

In this context, the Flux job shell provides the job-local execution and 
control context through which processes running in a Flux job interact 
with the Flux runtime.
It hosts job-facing interfaces (possibly through the PMIx plugin) and 
translates or forwards dynamic allocation messages between the application 
and the Flux job manager.

In addition to it's role managing state transitions as indicated in RFC 27, 
the Flux job manager now also mediates dynamic allocation requests.

A Flux scheduler's role is passively processing dynamic resource allocation 
messages sent by the job manager on behalf of jobs.

A high-level overview is provided in the following figure.

.. figure:: images/dyn_alloc.png
  :width: 650
  :alt: Flux Dynamic Resource Allocation overview
  :align: center

  Overview of dynamic allocation communication.

A Flux Job triggers a dynamic reallocation through a) the PMIx plugin with a 
``PMIx_Allocation_request`` which sends a dynamic allocation request to the shell's 
``alloc`` plugin with a ``shell.realloc`` request, or b) directly through a 
``shell.realloc`` request.

The Flux shell sends a dynamic reallocation request to the local job manager 
with a ``job_manager.realloc`` request. The job manager then forwards the 
request on behalf of the Flux shell to the local scheduler with a 
``sched.realloc`` request.

A simple scheduler satisfies ``sched.realloc`` requests by the 
first-in-first-out principle.
More complex schedulers MAY consider multiple ``sched.realloc`` requests 
and process them out of order to prioritize or balance measures of success 
such as resource utilization or fairness.
Schedulers who do not support DRM SHALL respond with the UNSUPPORTED type.

The response from the scheduler contains a concrete reallocation action to 
adapt a job's resource set and is processed by the job manager by applying 
required changes to the job. This includes adding any additionally provided 
resources to the job's resource set and sending a response for the 
outstanding dynamic allocation request to the shell.

The response from the job manager is processed by the shell by applying 
required changes to the job runtime environment. This includes sending a 
response for the outstanding dynamic allocation request to the job or PMIx 
plugin.

Since removing resources requires prior adaptation of the job (such as 
terminating processes on the indicated resources), the actual release of 
resources from a job's resource set is deferred until explicitly released 
by the job with a ``shell.release``.

When the shell receives a ``shell.release`` and corresponding job and shell 
processes have terminated, the job execution service responds with a 
``release`` response (with ``final=false``) to the streaming RPC defined in 
RFC 32 to release resources back to the job manager.

The job manager then releases resources back to the scheduler with a 
``sched.free`` call as defined in RFC 27.

Abstract, dynamic resource allocation requests are expressed as a **jobspec** 
object (RFC 25 or later). Concrete resource assignments are expressed as an 
**R** object (RFC 20 or later). These objects are stored in the KVS per the 
job schema (RFC 16).

When adding or removing resources to/from a job's allocation, the Flux job 
manager SHALL emit corresponding job lifecycle events such as ``alloc``, 
``resource-update``, ``release``, and ``free`` (RFC 21).

This RFC describes the RPC messages related to the job manager <-> scheduler 
interaction. 

.. note::
   TODO: Where should we describe the remaining RPCs?

Design Criteria
***************

- Enable optional support for dynamic (malleable and evolving) allocations
- Ensure compatibility with the ``PMIx_Allocation_request``

Implementation
**************

Realloc
=======

The job manager SHALL send a ``sched.realloc`` request when 
receiving a realloc request from a shell.

The request payload consists of a JSON object with the following 
REQUIRED keys:

job id
  (integer) ID of the job this request relates to

AT LEAST ONE of the following two keys is REQUIRED:

spec_add
  (object) jobspec object (RFC 25 or later) matching resources to be added

spec_sub
  (object) jobspec object (RFC 25 or later) matching a subset of job resources 
  to be removed.

The following key is OPTIONAL:

R
  (object) R object (RFC 20 or later) referencing a certain set of resources 
  this request applies to.

Example for a REALLOC request forwarded by the job manager to the scheduler 
to support the addition of four nodes with two cores each:

.. code-block:: json

  {
     "job_id": 42,
     "spec_add": {
        "version": 1,
        "resources": [
           {
              "type": "node",
              "count": 4,
              "with": [
                 {
                    "type": "slot",
                    "count": 1,
                    "label": "default",
                    "with": [
                       {
                          "type": "core",
                          "count": 2
                       }
                    ]
                 }
              ]
           }
        ],
        "tasks": [
           {
              "command": ["app"],
              "slot": "default",
              "count": {
                 "per_slot": 1
              }
           }
        ],
        "attributes": {
           "system": {
              "duration": 3600.0,
              "cwd": "/home/flux",
              "environment": {
                 "HOME": "/home/flux"
              }
           }
        }
     }
  }

The response payload is a JSON object with the following REQUIRED keys:

alloc_id
  (integer) Unique ID assigned to this request by the scheduler

type
  (integer) response type in the range of 0 through 3

There are three response types:

SUCCESS (0)
  Scheduler has decided on a resource reallocation action

DENY (1)
  The scheduler decided to not consider this realloc request

CANCEL (2)
  The realloc request was canceled by a ``sched.cancel`` request

UNSUPPORTED (3)
   Realloc requests are not supported. Schedulers who do not support 
   DRM SHALL immediately respond with the UNSUPPORTED type. 

If response type is SUCCESS, at least one of the following additional keys is 
REQUIRED:

R_delta_add
  (object) R object (RFC 20 or later) describing resources to be added

R_delta_sub
  (object) R object (RFC 20 or later) describing resources to be removed

If resources are to be removed, the Flux job manager SHALL wait until the job 
execution service sends a ``<service>.release``, after which it SHALL send 
one or more ``sched.free`` requests to release allocated resources to the 
scheduler (RFC 27).

Example of a SUCCESS response for a REALLOC request:

.. code-block:: json

  {
      "alloc_id": 12321234,
      "type": 0,
      "R_delta_add": {
         "version": 1,
         "execution": {
            "R_lite": [
               {
                  "rank": "19-22",
                  "children": {
                     "core": "0-47",
                     "gpu": "0-7"
                  }
               }
            ],
            "nodelist": [
               "node[186-189]"
            ],
            "nslots": 32,
            "starttime": 1676560542,
            "expiration": 1676562342
         }
      }
  }


Realloc Cancel
==============

The job manager MAY send a ``sched.realloc_cancel`` request to cancel a ``sched.realloc``
request, as described in :doc:`RFC 6 <spec_6>`.

matchtag
   (*integer*, REQUIRED) The matchtag of the request to be canceled.


References
##########

.. [#f1] `Process Management Interface for Exascale (PMIx) Standard Version 5.0 <https://pmix.org/uploads/2023/05/pmix-standard-v5.0.pdf>`__, p. 199, PMIx Administrative Steering Committee (ASC), 2023.