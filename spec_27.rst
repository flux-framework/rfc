.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_27.html

27/Flux Resource Allocation Protocol Version 1
==============================================

This specification describes Version 1 of the Flux Resource Allocation
Protocol implemented by the job manager and a compliant Flux scheduler.

-  Name: github.com/flux-framework/rfc/spec_27.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`14/Canonical Job Specification <spec_14>`

-  :doc:`16/KVS Job Schema <spec_16>`

-  :doc:`20/Resource Set Specification Version 1 <spec_20>`

-  :doc:`21/Job States and Events <spec_21>`

-  :doc:`23/Flux Standard Duration <spec_23>`


Background
----------

The Flux job manager's role is managing the queue of pending job requests
and transitioning jobs through the job states defined in RFC 21, actively
initiating actions in each state.  A Flux scheduler's role is passively
fulfilling resource allocation requests that the job manager makes on
behalf of jobs.

A scheduler implementation registers the generic service name ``sched``
and provides several well known service methods.  The job manager requests
resources from the scheduler with a ``sched.alloc`` request when a job enters
SCHED state.  It releases resources with a ``sched.free`` request when a job
enters CLEANUP state.

The simplest imaginable scheduler satisfies ``sched.alloc`` requests in order
until it is out of resources, then blocks until ``sched.free`` requests
release enough resources to satisfy the next ``sched.alloc`` request.
More complex schedulers consider multiple ``sched.alloc`` requests and
satisfy them out of order to prioritize or balance measures of success
such as resource utilization or fairness.

Abstract resource allocation requests are expressed as a *jobspec* object
(RFC 14).  Concrete resources assignments are expressed a an *R* object
(RFC 20).  These objects are stored in the KVS per the job schema (RFC 16).
The ``sched.alloc`` request implicitly refers to *jobspec* in the KVS by job ID,
while the ``sched.alloc`` response and ``sched.free`` request implicitly refer
to *R* in the KVS by job ID.

This RFC describes the RPC messages outlined above.  It also describes the
initialization messages used to establish parameters for scheduler operation
and identify resources that are already allocated at scheduler startup.
It does not cover the mechanism by which a scheduler discovers the initial
inventory of resources.


Design Criteria
---------------

- Support multiple scheduler implementations, minimizing repeated code
  in schedulers.

- Allow the maximum number of outstanding allocation requests sent by
  the job manager to be controlled by the scheduler.

- Allow the scheduler module to be reloaded with recovery of resource
  allocations of running jobs.

- Allow the scheduler module to abort (return from its module thread
  unexpectedly) without impacting running work.

- Send allocation requests to scheduler in priority, submit time order.

- Inform scheduler of job priority and submit time so it can reorder requests
  internally, combining these factors with others.

- Support job cancellation in SCHED state.

- Support job priority change in SCHED state.

- The resource allocation protocol should not present obstacles to scaling
  to O(1M) jobs in SCHED state.

- The protocol should not inhibit scaling job throughput to O(100) jobs per
  second.

- Capture scheduler specific job annotations for display by the job listing
  tool (e.g. start time estimates).


Implementation
--------------

To escape scalability limitations of the Flux "tag pool", ``sched.alloc`` and
``sched.free`` RPCs use the job ID to match requests and responses, and set the
RFC 6 matchtag message field to zero.  It follows that:

- The job ID MUST appear in the ``sched.alloc`` and ``sched.free`` request
  and response message payloads.

- There SHALL NOT be more than one ``sched.alloc`` or ``sched.free`` request
  in flight for each job, since otherwise a request could not be uniquely
  matched to a response using the job ID.

- The errnum field in ``sched.alloc`` and ``sched.free`` response messages
  MUST be set to zero, even if the response indicates an error.  Otherwise,
  the message payload could not include the job ID since RFC 6 defines the
  payload of an error response to be optional error text.

- The job manager SHALL treat a conventional Flux error response to
  ``sched.alloc`` or ``sched.free`` with a nonzero errnum field as a
  scheduler fatality, and SHALL not send further requests to the scheduler
  until it receives a new ``job-manager.sched-ready`` request (see Finalization
  below).

The other RPCs behave conventionally.

A detailed description of these RPCs follows.


Hello
~~~~~

Before any other RPCs are sent to the job manager, the scheduler SHALL
send an empty request to ``job-manager.sched-hello`` and wait for a response.

The response payload SHALL consist of a JSON object with one key: ``alloc``,
whose value is an array of zero or more jobs with allocated resources.
Each array entry SHALL be a JSON object with the following REQUIRED keys:

id
  (integer) job ID

priority
  (integer) priority in the range of 0 through 4294967295

userid
  (integer) job owner

Example:

.. code:: json

   {
     "alloc": [
       {
         "id": 1552593348,
         "priority": 43444,
         "userid": 5588,
       },
       {
         "id": 1552599944,
         "priority": 222,
         "userid": 5588,
       }
     ]
   }

For each job in the response, the scheduler SHALL mark its assigned resources
*allocated* internally.  It MAY look up *R* in the KVS by job ID according
to the job schema (RFC 16).

If an error response is returned to the ``job-manager.sched-hello`` request,
the scheduler SHALL log the error and exit its module thread.


Ready
~~~~~

Once the scheduler has processed the ``job-manager.sched-hello`` handshake,
it SHALL notify the job manager that it is ready to accept allocation requests
by sending a request to ``job-manager.sched-ready``.

The request payload SHALL consist of a JSON object with the following
REQUIRED key:

mode
  (string) selected concurrency mode

The mode string SHALL be one of the following:

single
  The job manager SHALL send a ``sched.alloc`` request only when there are
  no outstanding ``sched.alloc`` requests.  This mode is only useful for simple
  schedulers that run jobs strictly in the job manager queue order.

unlimited
  The job manager SHALL send a ``sched.alloc`` request for all jobs in SCHED
  state, with no limit on concurrency.

Example:

.. code:: json

   {"mode":"unlimited"}

The response payload SHALL be empty.

After responding to the ``job-manager.sched-ready`` request, the job manager
MAY immediately begin sending ``sched.alloc`` and ``sched.free`` requests.

If an error response is returned to the ``job-manager.sched-ready`` request,
the scheduler SHALL log the error and exit its module thread.


Alloc
~~~~~

The job manager SHALL send a ``sched.alloc`` request when a job enters SCHED
state, and concurrency criteria established by the initialization handshake
are met.  The request payload consists of a JSON object with the following
REQUIRED keys:

id
  (integer) job ID

priority
  (integer) priority in the range of 0 through 4294967295

userid
  (integer) job owner

Example:

.. code:: json

   {
     "id": 1552593348,
     "priority": 53444,
     "userid": 5588,
   }

Upon receipt of the ``alloc`` request, the scheduler SHALL look up *jobspec*
in the KVS by job ID according to the job schema (RFC 16).

The response payload is a JSON object with the following REQUIRED keys:

id
  (integer) job ID

type
  (integer) response type in the range of 0 through 3

There are four response types:

SUCCESS (0)
  Resources have been allocated

ANNOTATE (1)
  The scheduler wishes to annotate the job (see below)

DENY (2)
  The job cannot be scheduled

CANCEL (3)
  The alloc request was canceled by a ``sched.cancel`` request (see below).

The ``alloc`` request MAY receive multiple responses.

Alloc Success
^^^^^^^^^^^^^

If resources can be allocated, the scheduler SHALL ensure that *R* has
been successfully committed to the KVS per the job schema (RFC 16)
before responding.

In addition to the above REQUIRED keys, the SUCCESS response includes
the OPTIONAL key:

annotations
  (object) key value pairs

Example:

.. code:: json

   {
     "id": 1552593348,
     "type": 0,
     "annotations": {
       "sched": {
         "resource_summary":"rank[0-1]/core0"
       }
     }
   }

If present, the job manager SHALL update the job's annotation dictionary
as described in the next section.  The scheduler MAY delete annotations
such as ``sched.t_estimate`` that are not relevant now that the allocation
request has been satisfied.

The job manager posts an ``alloc`` event in response to the successful
allocation of resources.  A snapshot of job's annotation dictionary, after
the above update, is included in the ``alloc`` event context per RFC 21,
thus preserving it in job record when the allocation is successful.

After the SUCCESS response, the ``sched.alloc`` request is complete and may be
retired by the job manager and scheduler.

Alloc Annotate
^^^^^^^^^^^^^^

While a job is in SCHED state, the scheduler MAY send multiple ANNOTATE
type responses to the ``sched.alloc`` request to update scheduler-defined
information for display by the job listing tool.

In addition to the above REQUIRED keys, the ANNOTATE response includes
the REQUIRED key:

annotations
  (object) key value pairs

The job manager SHALL maintain a dictionary of annotations for each job.

Each ANNOTATE response and the SUCCESS response (if it contains annotations)
SHALL update the dictionary according to the following rules:

- If a key exists and is a dictionary, and the new value is a
  dictionary, the rules below SHALL be applied to the dictionary
  recursively.

- If a key exists, its value SHALL be replaced with the new value.

- If a key exists and the new value is JSON null, the key SHALL be removed.

- If a key does not exist, the key SHALL be added with the new value.

The key MAY be one of the following:

sched
  (dictionary) dictionary object containing scheduler specific annotations

sched.t_estimate
  (double) estimated absolute start time in seconds since UNIX epoch

sched.reason_pending
  (string) human readable reason job is pending

sched.resource_summary
  (string) human readable overview of assigned resources

sched.queue
  (string) human readable identification of job queue

user
  (dictionary) dictionary object containing user specific annotations

A scheduler MAY define additional ``sched`` keys as needed.

A value MAY be any valid JSON value.

Example:

.. code:: json

   {
     "id": 1552593348,
     "type": 1,
     "annotations": {
       "sched": {
         "t_estimate": 593016000.0,
         "reason_pending": "requested GPUs are unavailable"
       }
     }
   }

Annotations SHALL be considered *volatile* until a SUCCESS response is received
to the ``sched.alloc`` request, as described in Alloc Success above.
Annotations SHALL be discarded by the job manager if the allocation fails.

Alloc Deny
^^^^^^^^^^

If the resource request can never be fulfilled, the scheduler SHALL
respond to the ``sched.alloc`` with a DENY type response.

In addition to the above REQUIRED Keys, the DENY response includes
the OPTIONAL key:

note
  (string) the reason why the allocation cannot ever be granted

Example:

.. code:: json

   {
     "id": 1552593348,
     "type": 2,
     "note": "more nodes requested than configured"
   }

If present, the note SHALL be added to the ``exception`` event context
generated by the job manager when processing the allocation failure.

After the DENY response, the ``sched.alloc`` request is complete and may be
retired by the job manager and scheduler.

Alloc Cancel
^^^^^^^^^^^^

When the scheduler receives a ``sched.cancel`` request for a job (see below),
it SHALL respond to the corresponding ``sched.alloc`` request with response
type CANCEL.  Only the REQUIRED keys above are allowed in a CANCEL response.

Example:

.. code:: json

   {
     "id": 1552593348,
     "type": 3
   }

After the CANCEL response, the ``sched.alloc`` request is complete and may be
retired by the job manager and scheduler.


Cancel
~~~~~~

The job manager may cancel a pending ``sched.alloc`` request by sending
a request to ``sched.cancel`` with payload consisting of a JSON object
with the following REQUIRED key:

id
  (integer) job ID

Example:

.. code:: json

   {
     "id": 1552593348
   }

The scheduler SHALL NOT respond directly to the ``sched.cancel`` request.
Instead, if a ``sched.alloc`` request is pending for the specified job,
it SHALL respond to the ``sched.alloc`` request with a CANCEL response
as described above.  If the specified job does not have a pending
``sched.alloc`` request, the request SHALL be ignored by the scheduler.

Note that receipt of a ``sched.cancel`` does not necessarily indicate
that the *job* is canceled. For example, the job manager may cancel all
outstanding ``sched.alloc`` requests in response to the queue being
administratively disabled, or to make room for higher priority jobs
in ``single`` mode.


Prioritize
~~~~~~~~~~

When jobs with outstanding ``sched.alloc`` requests are re-prioritized,
the job manager notifies the scheduler by sending a ``sched.prioritize``
request.  The request payload consists of a JSON object with the following
REQUIRED key:

jobs
  (array) list of [id, priority] tuples

Each tuple SHALL consist of a two element array, containing:

[0]
  (integer) job ID

[1]
  (integer) priority in the range of 0 through 4294967295

Example:

.. code:: json

   {
     "jobs":[
       [49056579584, 444],
       [57428410368, 298],
       [63988301824, 343205],
       [69675778048, 99]
     ]
   }


Job IDs which cannot be correlated to a pending ``sched.alloc`` request
may be safely ignored.

No response is sent to the ``sched.prioritize`` request.

.. note::
    A job manager priority plugin MAY initiate a priority update of many
    jobs at once.  The job manager captures these updates in a single
    ``sched.prioritize`` request.


Free
~~~~

The job manager SHALL send a ``sched.free`` request when a job that is
holding resources enters CLEANUP state.  The request payload consists of
a JSON object with the following REQUIRED key:

id
  (integer) job ID

Example:

.. code:: json

   {
     "id": 1552593348
   }

Upon receipt of the ``sched.free`` request, the scheduler MAY look up *R*
in the KVS by job ID according to the job schema (RFC 16).
It SHOULD mark the job's resources as available for reuse.

Once the ``sched.free`` request has been processed by the scheduler, it SHALL
send a response with payload consisting of a JSON object with the following
REQUIRED key:

id
  (integer) job ID

Example:

.. code:: json

   {
     "id": 1552593348
   }

After the ``sched.free`` response, the request is complete and may be
retired by the job manager and scheduler.


Finalization
~~~~~~~~~~~~

If the job manager receives a conventional Flux error response to
a ``sched.alloc`` or ``sched.free`` request, it SHALL log the error
and suspend scheduling operations.  This ensures that, if the scheduler
is not loaded, and the broker responds with an ENOSYS error on its behalf,
the job manager behaves appropriately.

Similarly, if the job manager receives a ``disconnect`` request from the
scheduler, it SHALL suspend scheduler operations.

Operations MAY resume if the scheduler re-establishes itself with the
``job-manager.sched-hello`` and ``job-manager.sched-ready`` handshakes.


Exceptions
~~~~~~~~~~

When a job encounters a fatal exception, the job manager transitions it
to CLEANUP state.

Upon the job entering CLEANUP state, the job manager sends a ``sched.cancel``
request on its behalf if the job has an outstanding ``sched.alloc`` request.
If the job is holding resources when it enters CLEANUP, the job manager sends
a ``sched.free`` request.

If the scheduler is monitoring job exceptions, it SHOULD NOT react in ways
that might conflict with the job manager's actions.
