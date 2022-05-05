.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_33.html

33/Multi-Level Queue Scheduling Architecture
=================================================

This document describes a software architecture for multi-level queue job
scheduling within Flux.

-  Name: github.com/flux-framework/rfc/spec_33.rst

-  Editor: Dong H. Ahn <ahn1@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`14/Canonical Job Specification <spec_14>`

-  :doc:`25/Job Specification Version 1 <spec_25>`

-  :doc:`27/Flux Resource Allocation Protocol Version 1 <spec_27>`


Background
----------

High performance computing (HPC) workloads are becoming
increasingly more diverse. The convergence of traditional HPC and new
simulation, analysis, and data-science approaches including artificial
intelligence (AI) provides unprecedented opportunities for discovery, but also
creates diverse workloads more than ever before. Workloads from different users
and teams often demand highly specialized scheduling behaviors. Thus, Flux
MUST provide advanced scheduling capabilities with high levels of
flexibility and extensibility commensurate with this modern-day demand,
which prevents the traditional monolithic software approach.
This document is prepared to present a distributed software
architecture to enable multi-level queue job scheduling, a key advanced
scheduling capability within Flux.


Definition and Goal
-------------------

Flux's multi-level queue job scheduling subsystem refers to
the key distributed services, interfaces and mechanisms needed to provide
multi-level queue-based job scheduling within Flux. A multi-level queue
scheduler (MLQS) specifically refers to the scheduler service component of this
subsystem. The software architecture of this subsystem dictates the role
of the distributed components that participate in this subsystem which includes
MLQS, job manager, job list, and user accounting database, and how they SHOULD interact
with one another while maintaining a consistent view on the multi-level job queues
in use.

This document also defines the concept of multi-level job queues
within Flux and specifies the software architecture to enable
them with respect to:

- Separation of concerns among the components that take part in Flux's
  multi-level queue job scheduling subsystem;

- Key interfaces and mechanisms by which the main components
  of this architecture MUST interact with one another to achieve high degrees of
  composability, flexibility and extensibility;

- Desired attributes needed for this architecture including queue configuration
  consistency among the distributed components needed to make this subsystem
  highly integral, easy to configure and easy to understand.


Overview
--------

.. mermaid::

   flowchart TD
       U[User] -- 1. Add a specific queue into Jobspec  --> J
       J{{Jobspec: .attributes.system.queue=Queue2}} -- 2. Request via job.submit --> M[Job Manager]
       M -- 3. Request via sched.alloc --> SQ2[Queue1]
       M[Job Manager] -- 8. Fetch Job Info --> JL[Job List]
       JL[Job List] -- 9. Query jobs --> U{User}
       SQ2 -- 7. Reply via type=ANNOTATE sched.queue=Queue2 --> M
       subgraph MAIN[Multi-Level Queue Scheduler]
       subgraph SG[.]
       style SG stroke-dasharray: 5 5
       SQ1([Queue1])
       SQ2([Queue2])
       SQ3([...])
       SQN([QueueN])
       end
       subgraph PL[MLQS-Specific Per-Queue Controller]
       style PL stroke-dasharray: 5 5
       P[[Policies]] -. 4. Effect job execution order .-> SQ2
       L[[Limits]] -. 5. Prevent abuse.-> SQ2
       S[[Parameters]] -. 6. Optimize queuing performance.-> SQ2
       end
       end

The above figure identifies some of the core distributed components within this subsystem
and illustrates step by step how they interact with one another as well as with users.
At 1, a user first specifies a queue name to be passed to the jobspec before it
gets submitted to the Flux job manager at 2.

When this job becomes eligible to run, the job manager requests resources from the
scheduler. Differently from a single queue scheduler, however, MLQS MAY have multiple
named queues. To determine which queue MUST be used for this job, MLQS reads the queue
name from a key within the jobspec passed through the request and enqueues this job into
the correspondingly named queue as shown at 3.

A named queue such as ``Queue2`` shown in the figure MAY use distinct policies as pertaining
to queuing (which includes backfilling), scheduler-specific limits and internal
queuing operation control parameters, respectively at 4, 5, and 6.
They are collectively referred to as the MLQS-specific per-queue
controller. Combined together, they determine how the jobs within their corresponding
queue are assigned to resources.
They effect job execution order and queuing behaviors
to enforce the fair share usage of resources while maximizing the resource utilization
and preventing undesirable effects such as a single user monopolizing system resources at the
expense of resource starvation of other users as well as optimizing the queuing behaviors.

At 7, MLQS replies to the job manager which MAY include the queue name as an annotation.
The queue name information for this job SHALL then become available to the job
listing service at 8. Ultimately, the queue information of the job becomes available
for users through the use of standard job listing tools within Flux.


Separation of concerns
----------------------

The multi-level queue scheduling architecture is designed to facilitate a good separation
of concerns and creations of swappable MLQS implementations. This section discusses
how this architecture separates key concerns out across different components
to enable the MLQS component to be singly focused while Flux's core infrastructure
handles other relevant responsibilities.

The main responsibility of MLQS is to create and use multiple
job queues to assign jobs to a disjoint or overlapping set of compute or other
resources (e.g., compute nodes, cores or multi-tiered storage amount). Each queue
MAY be specialized by the help of per-queue controllers. However, these controllers
SHOULD apply the controls that only pertain to and can only be performed by MLQS.
MLQS assumes the following checks have already been applied by other components
before the job manager request resources for a job:

- Authorization of its user's access to the requesting queue;

- Its priorities with respect to its user's fair resource share and other factors
  on the requesting queue;

- Limits that are not MLQS-specific such as various job count limits (e.g.,
  rejecting the job if it causes a maximum number of allowed active jobs across all queues
  or on the requesting queue to exceed).

These checks MAY be performed by the job manager with the help
of multi-factor priority plugin and user accounting database.

Once the above checks have completed on the job, it is sent to MLQS to be enqueued
into the corresponding queue. Each queue is subject to MLQS-specific controller.
The policy controller within MLQS controls the queuing and backfilling behavior
of the corresponding queue. Typically, the queue maintains pending jobs
in their assigned priority order, and during each scheduling cycle, MLQS assigns resources
to jobs in this sorting order. Because the priorities of jobs are assigned before
the jobs enter MLQS, this queuing semantics is nothing but first come first served
(FCFS). A well-known problem with FCFS is resource under-utilization where resources
are idling when the resource requirement of the job that
is in the front of the queue cannot be satisfied.
To overcome this limitation, the policy controller MAY enable and control
backfilling behavior: allowing those jobs that appear later in the queue
to have their resources assigned first even if the job in the front of the queue
cannot be assigned with resources (e.g., a sufficient amount of resources
is currently unavailable). The controller determines what guarantees
the earlier jobs will have when later jobs are *backfilled*. This
can include but not be limited to well-known time guarantees: i.e., later jobs will
be backfilled as far as this does not delay the start time of earlier jobs up to ``K`` jobs
where ``K`` can vary from ``1`` to ``unlimited``. A backfilling
policy can be named with respect to the ``K`` parameter: EASY backfilling (``K = 1``),
CONSERVATIVE backfilling (``K = unlimited``) and HYBRID backfilling (``K > 1 and < unlimited``).

The limit controller within MLQS controls MLQS-specific limits that
cannot otherwise accurately be enforced. The prominent limits of this
class are various resource limits. Because a same jobspec can result
in a different amount of resources assigned to the job (e.g., a jobspec
requesting a single CPU core can be assigned to the entire compute node resources when
node exclusive scheduling is used), only the limits controller within MLQS
can enforce resource limits such as a maximum number of compute nodes per job
or across all running jobs per user on the requesting queue.

The parameter controller within MLQS further controls some of the internal
queuing operations to tune them for the workload characteristics.
For instance, when a queue must handle massively large numbers of small jobs,
limiting the number of jobs for each scheduling loop to consider or not
invoking scheduling loop per each job enqueue event can significantly
improve resource utilization: i.e., faster internal queuing operations
can inject jobs more promptly, avoiding the delayed idling of resources.


Interfaces
----------

The following details the key Flux interfaces that enable this architecture:

- The queue name specified by a user SHALL be stored in the
  ``.attributes.system.queue`` key within the jobspec (RFC 14 and 25). This
  MAY be used by MLQS to find and target the corresponding named queue.

- The ``sched.alloc`` streaming RPC is used for the job manager to request resources
  from MLQS (RFC 27).

- One or more replies from MLQS MAY include the queue name in a payload key when
  it either has successfully allocated resources to the job or wishes to annotate
  the job (RFC 27).

- Flux job listing tools SHALL be capable of presenting the named queue into which a job
  has been enqueued or scheduled. It MAY also provide capabilities to identify the named
  queue easily for every job: (e.g., listing jobs in their scheduling queue name order).


Configuration Consistency
-------------------------

The above separation of concerns can be provided only when all of the distributed
components that participate in this subsystem share the consistent view
on the multi-level job queues. The best design to ensure or enforce configuration
consistency for this architecture is actively being discussed, and the design will
be specified in this document once finalized. This will include but not be
limited to how the MLQS-specific per-queue controller can be configured,
in particular when the configuration must come from external sources
such as use accounting database.


Use cases
----------

- Ensure multiple users share and use different sets of compute resources
  without suffering from resource starvation for each set by partitioning
  resources into disjoint or overlapping sets and setting default limits (e.g.,
  the max amount of compute resources) equally on all user jobs requesting to
  access each set. Each resource partition can be managed by a distinct queue and
  its limits can be enforced with the per-queue limit control.

- Enable specific users to run their high urgency jobs faster by
  overriding the default limit on a resource partition on them. This can
  be done by overriding the limit for the users by using the general limits
  control (i.e., not MLQS specific).

- Enable specific users to run jobs across a large resource set (e.g., the
  entire system) in the presence of such smaller partitions whose
  resources overlap. This can be achieved by configuring and using
  multiple queues that manage overlapping compute resources and access control.

- Enable specific users to run their jobs as quickly as possible without
  being bounded by either the queuing behavior or their assigned
  fair resource shares by boosting their priorities on the queue.

- Allow some user jobs to be preempted. This can be achieved by
  introducing a preemptible queue and a non-preemptible queue each managing
  an overlapping resource set and by killing jobs from the preemptible queue
  when a job in the non-preemptible queue needs their resources.

