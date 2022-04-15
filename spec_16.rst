.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_16.html

16/KVS Job Schema
=================

This specification describes the format of data stored in the KVS
for Flux jobs.

-  Name: github.com/flux-framework/rfc/spec_16.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`12/Flux Security Architecture <spec_12>`

-  :doc:`14/Canonical Job Specification <spec_14>`

-  :doc:`15/Independent Minister of Privilege for Flux: The Security IMP <spec_15>`

-  :doc:`18/KVS Event Log Format <spec_18>`

-  :doc:`20/Resource Set Specification <spec_20>`

-  :doc:`21/Job States <spec_21>`


Background
----------


Components that use the KVS job schema
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Instance components have direct, read/write access to the primary KVS
namespace:

-  *Ingest agent*

-  *Job manager*

-  *Exec service*

-  *Scheduler*

Guest components have direct, read/write access to a private KVS namespace:

-  *Job shell*

-  *User tasks*

-  *Command line tools*


Job Life Cycle
~~~~~~~~~~~~~~

A job is submitted to the *ingest agent* which validates jobspec, adds
the job to the KVS, and informs the *job manager* of the new job.
Upon success, the jobid is returned to the user. The *job manager* then
takes the active role in moving a job through its life cycle:

1) If a job has dependencies, interacting with a job dependency
   subsystem to ensure they are met before proceeding.
2) Submitting an allocation request to the *scheduler* to obtain resources.
3) Once resources are allocated, submitting a start request to the
   *exec service*.
4) The *exec service* starts *job shells* directly in a single-user instance.
   In a multi-user instance, it directs the IMP to start them with guest
   credentials, with appropriate containment.
5) The *job shell* examines jobspec and allocated resource set, then
   launches tasks on local resources. It provides standard I/O, parallel
   bootstrap, signal propagation, and exit code collection services.
   It is a user-replaceable component.
6) Once tasks exit, or an exceptional condition such as cancellation or
   expiration of wall clock allocation occurs, the *exec service* cleans up
   any lingering tasks and *job shells*, and notifies the *job manager* which
   frees resources back to the *scheduler*.

The job is now complete.


Implementation
--------------


Primary KVS Namespace
~~~~~~~~~~~~~~~~~~~~~

The Flux instance has a default, shared namespace that is accessible
only by the instance owner.

All job data is stored under a ``jobs`` directory in the primary
namespace. Each job has a directory under ``job.<jobid>``, where
``<jobid>`` is a unique sequence number assigned by the *ingest agent*.
Jobs listed in the ``jobs`` directory may need to be periodically
archived and purged to keep its size manageable in long-running
instances.


Guest KVS Namespace
~~~~~~~~~~~~~~~~~~~

A guest-writable KVS namespace is created by the *exec service*
for the use of the *job shell* and the application. While the job
is active, this namespace is linked from ``job.<jobid>.guest``
in the primary KVS namespace. While linked, it can be changed
by the guest components without impacting performance of the primary
namespace, while still being accessible through the link in the
primary namespace.

When the job transitions to inactive, the final snapshot of the
guest namespace content is linked by the *exec service* into the primary
namespace, and the guest namespace is destroyed.


Access to Primary Namespace by Guest Users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Guests may access data in the primary KVS namespace only through instance
services that allow selective guest access, by proxy or by staging copies
to the guest namespace.

Guest access for primary namespace contents ``R``, ``J``, ``jobspec``, and
``eventlog`` is provided via a proxy service in the instance.


Event Log
~~~~~~~~~

Active jobs undergo change represented as events that are recorded under
the key ``job.<jobid>.eventlog``. A KVS append operation
is used to add events to this log.

Each append consists of a string matching the format described in
:doc:`RFC 18 <spec_18>`.


Content Produced by Ingest Agent
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A user submits *J* with attached signature, as described in
:doc:`RFC 15 <spec_15>`.

The *ingest agent* validates *J* and if accepted, populates the KVS with:

``job.<jobid>.J``
   signed user request token for passing to IMP in a multi-user instance.

``job.<jobid>.jobspec``
   jobspec in JSON form, as described in :doc:`RFC 14 <spec_14>`

``job.<jobid>.eventlog``
   eventlog described above

The *ingest agent* logs one event to the eventlog:

``submit`` ``userid=UID urgency=N``
   job was submitted, with authenticated userid and urgency (0-31)


Content Consumed/Produced by Job Manager
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Upon notification of a new ``job.<jobid>``, the *job manager* takes
the active role in moving a job through its life cycle, and logs events
to the eventlog as described in :doc:`RFC 21 <spec_21>`.

When the *job manager* is restarted, it recovers its state by scanning
``jobs`` and replaying the eventlog for each job found there.


Content Consumed/Produced by Scheduler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the *scheduler* receives an allocation request containing a jobid,
it reads the jobspec from ``job.<jobid>.jobspec``.

The scheduler allocates resources by writing a resource set
as described in :doc:`RFC 20 <spec_20>`
to ``job.<jobid>.R`` and answering the allocation request.

The scheduler frees resources by answering the free request,
leaving ``R`` in place for job provenance. During a restart, the
*job manager* uses the eventlog to determine whether ``R`` is currently
allocated.


Content Consumed/Produced by Exec Service
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the *exec system* receives a start request containing a jobid,
it reads the ``job.<jobid>.R`` and ``job.<jobid>.jobspec``
and uses this information to launch *job shells* and subsequently tasks.

The *exec system* creates the job’s guest namespace and links it to
``job.<jobid>.guest``. Its initial contents are populated with

``exec.eventlog``
   An eventlog for the use of *job shells*, TBD.

Once all *job shells* have exited and all outstanding writes to
the guest namespace have stopped, the *exec system* links the guest
namespace into the primary KVS namespace before notifying the *job
manager* that the job is finished.


Content Produced/Consumed by Other Instance Services
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Other services not mentioned in this RFC MAY store arbitrary data associated
with jobs under the ``job.<jobid>.data.<service>`` directory,
where ``<service>`` is a name unique to the service producing the data.
For example, a job tracing service may store persistent trace data under
the ``job.<jobid>.data.trace`` directory.


Content Consumed/Produced by Other Guest Services
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Other guest services not mentioned in this RFC MAY store service-specific
data in the guest KVS namespace under ``<service>``, where ``<service>`` is
a name unique to the service producing the data.


Content Consumed/Produced by the Application
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The application MAY store application-specific data in the guest KVS
namespace under ``application``.


Content Consumed/Produced by Tools
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Tools such as parallel debuggers, running as the guest, MAY store data
in the guest KVS namespace under ``tools.<name>``, where ``<name>`` is
a name unique to the tool producing the data.
