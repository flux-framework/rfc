.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_33.html

33/Distributed Job Control Protocol
===================================

This specification describes the distributed protocol that the job
execution service uses to launch, monitor, and control a set of Flux job
shells.

-  Name: github.com/flux-framework/rfc/spec_33.rst

-  Editor: Mark A. Grondona <mark.grondona@gmail.com>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`21/Job States and Events <spec_21>`

-  :doc:`22/Idset String Representation <spec_22>`

-  :doc:`32/Flux Job Execution Protocol Version 1 <spec_32>`

Background
----------

RFC 32 describes the protocol between the execution service and job manager
used to initiate and control jobs during the execution phase.  Upon receipt
of a ``start`` request, the execution service is responsible for the launch,
monitoring, and control of job shells on all execution targets involved
in the job.

The Distributed Job Control Protocol describes how a set of execution service
broker modules interact in distributed fashion to meet the requirements of
executing job shells on behalf of the job manager.

The initial execution service was a minimum viable implementation concentrated
on rank 0, launching remote processes using the simple ``broker.rexec``
service.  In contrast, the Distributed Job Control Protocol sets the stage for
an implementation that

 - takes advantage of the tree based overlay network structure to optimize
   performance

 - is structured to allow running jobs to be recovered upon Flux system
   instance restart

 - incorporates design insights from the early WRECK prototype execution system

Design Criteria
---------------

The Distributed Job Control Protocol must adhere to the following criteria:

 - Avoid global distributed operations which would require all ranks to
   be online before the service is ready to execute work.

 - Avoid presenting obstacles to the scaling of job size, the number of jobs
   running concurrently, or job throughput.

 - Support recovery of running jobs after instance restart or execution
   module reload.

 - Support execution of a job prolog and/or epilog.

 - Support for collecting stdout and stderr from IMP and/or job shells

 - Support for a barrier implementation used by the job shells, so that
   the execution service may determine if shells exit early due to error.

 - Support partial release of allocated resources.

 - Support for job termination on job exceptions, job time limit, and other
   error conditions.

 - Support delivery of signals to jobs.

Implementation
--------------

Job execution modules SHALL be loaded on all ranks in an instance, and are
organized in a hierarchy with rank 0 at the root. Each module SHALL track
the state of all running jobs for itself and all of its children. This state
SHALL include at a minimum the jobid, userid, job state, and the idset of
execution targets on which the job has an allocation.

All job execution modules register a ``job-exec.hello`` service method.
Downstream execution modules send a ``hello`` request to their upstream
peer. An execution module SHALL wait to send a ``hello`` response to its
downstream peers until an initial ``hello`` response from upstream has been
received. In the case of rank 0, the job execution module SHALL wait to send
``hello`` responses until the initial RFC 32 ``hello`` response is received
from the job manager.

Responses to the ``job-exec.hello`` request are used to distribute job state
and other events downstream through the job execution module hierarchy.
These responses have a JSON object payload including the REQUIRED keys
``type``, ``idset``, and ``data``.

Supported types of ``job-exec.hello`` responses SHALL include at a minimum
the following:

state-update
 A ``state-update`` response is used to update the distributed state of
 jobs. The ``data`` object SHALL have a single key, ``jobs``, which SHALL
 be an array of (id, userid, type, idset) tuples. The ``type`` entry of the
 tuple SHALL indicate how the state is to be resolved on ranks in ``idset``.
 Possible values for ``type`` are described below.

When a job execution module receives a ``state-update`` response from
upstream, it SHALL take the following actions, depending on the value of
the ``type`` key:

add
  If the jobid already exists in the local module's state, then do nothing.

  Otherwise, if the provided ``idset`` intersects any child idset, then
  the module SHALL send a ``state`` response to matching children of type
  ``add``.  Then, the local module SHALL determine if the provided ``idset``
  contains its rank, and if so, the module SHALL execute the job locally
  using the currently selected execution implementation.

remove
  If the provided ``idset`` intersects any child idset, then the job exec
  module SHALL send a ``state`` response to matching children with type
  ``remove``. Then, the the referenced ``jobid`` SHALL be purged from the
  local module's state.

check
  If the provided ``idset`` intersects any child idset, then the job exec
  module SHALL send a ``state`` response to matching children with type
  ``check``.

  If the provided ``idset`` contains the local module's rank, then the
  module SHALL check if the referenced ``jobid`` exists locally. If not,
  then a job exception SHALL be raised.

The first response to ``job-exec.hello`` SHALL be of type ``state-update``.
The included ``jobs`` tuples SHALL all be of ``type=check`` and MUST
include the entire set of jobs which are expected to be currently running
on the execution targets of the current module and its children. If a job
execution module discovers a locally running job which is not in the initial
``state-update`` list, then the module SHALL terminate the job processes
and log an error.

When the rank 0 job execution module receives an RFC 32 ``start`` request
from the job manager, it SHALL determine the idset associated with the
job from *R*, and then locally issue a state update of type ``add``,
following the specification for ``add`` listed above.

While job execution is in progress, execution modules SHALL update their
upstream peer with the following status changes:

start
  when the local job shell has started
barrier
  the local job shell has entered a barrier
finish
  the local job shell has exited
exception
  a job exception has occurred
release
  all local work is completed, the resources on this rank may be released
  (e.g. after job epilog is complete)

Upon receiving one of the requests above, a job execution module MAY
attempt a reduction and SHALL forward the request upstream. On rank 0, the
job exec module SHALL collect and translate job execution module requests
to job-manager ``start`` response payloads including:

start
  after job exec ``start`` has been received from all ranks
finish
  after all job exec ``finish`` requests have been received from all ranks
exception
  forwarded immediately to job-manager
release
  release requests may be aggregated and forwarded in chunks to the job
  manager to allow for partial release.

Each job exec module SHALL subscribe to ``job-exception`` events and MUST
handle exceptions locally. For fatal job exceptions, the default behavior
SHALL be to kill the local job shell and its children.

After receiving the final ``release`` request from a downstream module,
the rank 0 job execution module SHALL perform the following final steps:

 - post a terminating event to the exec eventlog
 - copy guest namespace to primary namespace
 - issue a ``release`` response with final=true to the job manager
 - remove local state entry for the job
 - update distributed state so job is removed from all children

Job-Exec Hello Request
^^^^^^^^^^^^^^^^^^^^^^
The ``job-exec.hello`` request has no payload.

Job-Exec Hello Response
^^^^^^^^^^^^^^^^^^^^^^^

A ``job-exec.hello`` response payload SHALL be a JSON object containing
the following REQUIRED keys:

type
 (string) The response type

idset
 (string) RFC 22 Idset string indicating the ranks to which this response
 should be delivered

data
 (object) type-specific data

State-update
~~~~~~~~~~~~

The ``state-update`` ``hello`` response ``data`` object SHALL contain the
following REQUIRED keys:

jobs
  A list of job tuples where a tuple is an array ``[ id, userid, type, idset]``.

Where

id
  (integer) the job ID

userid
  (integer) the job user ID

idset
  (string) An RFC 22 idset string denoting all ranks which are included
  in the assigned resources for job ``id``.

type
  (string) The type of state update. One of ``add``, ``remove``, or ``check``.

Job-Exec Start Request
^^^^^^^^^^^^^^^^^^^^^^

A ``job-exec.start`` request SHALL be sent upstream by an execution module
once the job shell or IMP has been started. The payload SHALL be a JSON
object containing the following REQUIRED keys:

id
 (integer) the job ID

ranks
 (string) an RFC 22 Idset string of ranks on which the job shell has started


Job-Exec Barrier Request
^^^^^^^^^^^^^^^^^^^^^^^^

A ``job-exec.barrier`` request SHALL be sent upstream from a execution
module when the locally executed job shell enters a barrier. The payload
SHALL be a JSON object containing the following REQUIRED keys:

id
 (integer) the job ID

ranks
 (string) an RFC 22 Idset string of execution targets on which the shell
 barrier has been started.

seq
 (integer) a shell barrier sequence number

The upstream module SHALL respond to a ``job-exec.barrier`` request
once all job shells have entered the barrier with a matching sequence
number.


Job-Exec Finish Request
^^^^^^^^^^^^^^^^^^^^^^^

A ``job-exec.finish`` request SHALL be sent upstream by an execution
module once the job shell has exited. The payload SHALL be a JSON object
containing the following REQUIRED keys:

id
 (integer) the job ID

ranks
 (string) an RFC 22 idset string of execution targets on which the job
 shell has exited.

status
 (integer) the greatest job shell wait status among ``ranks``


Job-Exec Exception Request
^^^^^^^^^^^^^^^^^^^^^^^^^^

A ``job-exec.execption`` request SHALL be sent upstream by an execution
module when the module wishes to raise a execution related job exception. The
payload SHALL be a JSON object containing the following REQUIRED keys:

id
 (integer) the job ID

severity
 (integer) the exception severity

type
 (string) the exception type

note
 (string) a human readable description of the job exception


Job-Exec Release Request
^^^^^^^^^^^^^^^^^^^^^^^^

A ``job-exec.release`` request SHALL be sent upstream by an execution
module after the job shell has exited and any job epilog or other work
associated with the job has completed. The payload SHALL be a JSON object
with the following REQUIRED keys:

id
 (integer) the job ID

ranks
 (string) an RFC 22 Idset including the execution target ranks on which
 resources should be released

