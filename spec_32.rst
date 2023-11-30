.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_32.html

32/Flux Job Execution Protocol Version 1
========================================

This specification describes Version 1 of the Flux Job Execution Protocol
implemented by the job manager and job execution system.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_32.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

- :doc:`spec_14`
- :doc:`spec_15`
- :doc:`spec_16`
- :doc:`spec_21`
- :doc:`spec_27`

Background
----------

The job execution service launches Flux job shells on execution targets at
the behest of the job manager.  The job shells in turn launch one or more
user processes that comprise the job.  The job execution service thus acts
as an intermediary between the job manager and a set of job shells.

RFC 16 describes the division of labor among Flux job services, and how they
share information via the KVS Job Schema.  The Flux Execution Protocol version
1 defines the minimal interactions between the job manager and the execution
service needed to synchronize the concurrent progress of multiple jobs through
their running phase.

As a reminder, the job execution service runs as the unprivileged Flux
instance owner.  In a multi-user Flux instance, it launches Flux job shells
via the IMP as described in RFC 15, with the IMP managing the user transition
after authenticating the signed job request from the KVS.  The security
aspects of launching a job as another user are not reflected in the job
execution protocol.

Design Criteria
---------------

The job execution protocol must adhere to these criteria:

- Maintain a clean separation of concerns between job manager, scheduler,
  execution service, and Flux job shell.

- Avoid presenting obstacles to the scaling of job size, the number of jobs
  running concurrently, or job throughput.

- Communicate job problems to the job manager, such that the job manager can
  use this information to raise job exceptions.

- Support partial release of allocated resources to the scheduler, in case
  one or more execution targets cannot be expeditiously finalized.

- Communicate high level job results to the job manager upon job completion.

- Support execution service reload.

- Support execution service override by the Flux simulator.

Implementation
--------------

As with the scheduler RPCs described in RFC 27, ``<service>.start`` RPCs use
the job ID to match requests and responses, and set the RFC 6 matchtag message
field to zero.  It follows that:

- The job ID MUST appear in the ``<service>.start`` request and response
  message payloads.

- There SHALL NOT be more than one ``<service>.start`` request in flight for
  each job, since otherwise a request could not be uniquely matched to a
  response using the job ID.

- The errnum field in ``<service>.start`` response messages MUST be set to
  zero, even if the response indicates an error.  Otherwise, the message
  payload could not include the job ID since RFC 6 defines the payload of
  an error response to be optional error text.

- The job manager SHALL treat a conventional Flux error response to
  ``<service>.start`` with a nonzero errnum field as an execution service
  fatality, and SHALL not send further requests to the execution service
  until it receives a new ``job-manager.exec-hello`` request.

The other RPCs behave conventionally.

Hello
~~~~~

The Flux execution service SHALL register a service name with the job manager
on initialization.  This service MAY be ``job-exec`` or another name.  The
execution service calls the ``job-manager.exec-hello`` RPC whose request
payload SHALL be a JSON object containing with one REQUIRED key:

service
  (string) execution service name

Example:

.. code:: json

   {
     "service": "job-exec"
   }

If an execution service is already loaded, the job manager SHALL allow
the new one to override it.

The response payload SHALL be empty on success.  The job manager SHALL issue
a failure response if any jobs have an outstanding ``start`` request to an
existing execution service.  The execution service SHALL treat a failure
response to ``exec-hello`` as fatal.

Start Request
~~~~~~~~~~~~~

Once the execution service is registered, the job manager SHALL send
``<service>.start`` requests for any jobs that have been allocated resources.
Each ``start`` request begins a streaming RPC that remains active while the job
is running.  The request payload SHALL be a JSON object containing the
following REQUIRED keys:

id
  (integer) the job ID

userid
  (integer) the submitting userid

jobspec
  (object) *jobspec* object (RFC 14)

reattach
  (boolean) Set to True if broker has been restarted and job should still
  be running.


Example:

.. code:: json

   {
     "id": 1552593348,
     "userid": 5588,
     "jobspec": {},
     "reattach": false,
   }

The response payload SHALL be a JSON object containing the following REQUIRED
keys:

id
  (integer) the job ID, used by the job manager to match the response back
  to the request

type
  (string) the type of response (see below)

data
  (object) type-dependent data (see below)

There are four response types:

start
  Indicates that the job shells have started.  ``data`` is an empty object.
  Example:

  .. code:: json

     {
       "id": 1552593348,
       "type": "start",
       "data": {},
     }

release
  Release R fragment to job-manager.  ``data`` contains two keys:  ``ranks``
  (string), an idset representing subset of execution targets whose resources
  may be released; and ``final`` (boolean) a flag indicating whether all the
  job's execution targets have now been released.  Example:

  .. code:: json

     {
       "id": 1552593348,
       "type": "release",
       "data": {
         "ranks": "0-2",
         "final": true,
       },
     }

exception
  Raise an exception on the job as described in RFC 21.  ``data`` contains two
  required keys: ``severity`` (integer), the exception severity; and ``type``
  (string), the exception type.  A third key, ``note`` (string), is a human
  readable description of the exception which the job manager SHALL include
  in the exception context if present.  Example:

  .. code:: json

     {
       "id": 1552593348,
       "type": "exception",
       "data": {
         "severity": 0,
         "type": "timeout",
         "note": "resource allocation expired",
       },
     }

finish
  Job is complete. ``data`` contains one required key: ``status`` (integer),
  the numerically greatest wait status returned by the set of job shells.
  Example:

  .. code:: json

     {
       "id": 1552593348,
       "type": "finish",
       "data": {
         "status": 143,
       },
     }

An ``exception`` response MAY be sent at any point.  ``start`` and/or
``finish`` responses MAY be omitted depending on when a fatal exception occurs.
The execution service MUST always send a ``release`` response with ``final``
set to True.  The final ``release`` response SHALL be the last response sent
by the execution service for a given job ID and is interpreted as "end of
stream" by the job manager.
