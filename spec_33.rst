.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_33.html

33/Flux Job Queues
##################

This specification describes Flux Job Queues.  A Flux Job Queue is a named,
user-visible container for job requests sorted by priority.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_33.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_14`
- :doc:`spec_20`
- :doc:`spec_21`
- :doc:`spec_27`

Background
**********

Support for multiple queues is motivated by the following use cases:

- Schedule "debug" and "batch" jobs independently, on disjoint or overlapping
  resource sets.

- Allow jobs to be submitted in advance of dedicated application time,
  to run on a resource superset.

- Impose different limits on a given resource set.

- Implement a different priority scheme and/or scheduling algorithm on
  a given resource set.

- Allow only certain users or banks to access a given resource set.

- Allow for exceptions to limits and access controls.

.. note::
   Use cases are spelled out in more detail in
   https://github.com/flux-framework/flux-core/issues/4306

Design Criteria
***************

- Handle the motivating use cases in the background section.

- Minimize overhead for single-queue Flux instances, which will remain
  the common case for non-system instances.

- Minimize disruption to the original design of Flux with a single anonymous
  queue.

- Elevate named queues to a first class abstraction in Flux.

- Promote a separation of concerns among Flux components such as scheduler,
  job manager, accounting plugins, and Flux command line utilities.

- Avoid overloading the queue abstraction.  For example, a new queue should not
  be required merely to affect job priority or bypass limits (e.g. "standby",
  "expedite", or "exempt" queues).

Implementation
**************

A Flux Job Queue is a user-visible container for job requests stored in
priority order.

Queue configuration is OPTIONAL.  If queues are not configured, the Flux
instance SHALL have one anonymous queue.  If queues are configured, then
all queues SHALL be named.  If more than one named queue is configured,
one queue MUST be designated as the default queue by configuring
``policy.jobspec.defaults.system.queue`` (see below).

Queues MAY be independently configured with:

- jobspec defaults policy

- limits policy

- scheduler policy

- priority policy

- access policy

- resource subset

Policy Configuration
====================

A ``policy`` TOML table MAY specify queue policy that applies to all queues,
including the anonymous one, unless overridden on a per-queue basis.  This
table contains OPTIONAL sub-tables for ``jobspec.defaults``, ``limits``,
``access``, and ``scheduler``.

Each queue MAY contain a ``policy`` table.  If present, queue-specific policy
values SHALL override global policy values.

Jobspec Defaults Policy
-----------------------

The ``policy.jobspec.defaults`` table contains default values for jobspec
attributes that were not explicitly set by the user and MAY contain following
OPTIONAL keys.  The key names are identical to the corresponding jobspec
attribute names (RFC 14, 25).

policy.jobspec.defaults.system.duration
  (string) default duration, in Flux Standard Duration format (RFC 23).

policy.jobspec.defaults.system.queue
  (string) default queue name.

.. note::
   Jobspec defaults are applied at ingest to the unsigned copy of the jobspec
   held stored in the KVS under the ``jobspec`` key.  The original jobspec
   remains within the signed ``J`` key.

Limits Policy
-------------

The ``policy.limits`` table configures job limits and MAY contain the following
OPTIONAL keys.

policy.limits.job-size.max.nnodes
  (integer) maximum number of nodes.

policy.limits.job-size.max.ncores
  (integer) maximum number of cores.

policy.limits.job-size.max.ngpus
  (integer) maximum number of gpus.

policy.limits.job-size.min.nnodes
  (integer) minimum number of nodes.

policy.limits.duration
  (string) maximum job duration, in Flux Standard Duration format (RFC 23).

Scheduler Policy
----------------

The ``policy.scheduler`` table is read by the scheduler implementation
and is opaque to the rest of Flux.

Priority Policy
---------------

TBD

Access Policy
-------------

The ``policy.access`` table MAY restrict queue access by UNIX user and group.
It MAY contain following OPTIONAL keys:

policy.access.allow-user
  (list of strings) Specify a list of UNIX user names that are to be granted
  access.

policy.access.allow-group
  (list of strings) Specify a list of UNIX group names that are to be granted
  access.

The absence of ``allow-user`` and ``allow-group`` keys indicates that no queue
access restrictions are in place.  However, the access policy MAY be extended
by a jobtap plugin that enforces additional access conditions.  For example,
the flux-accounting multi-factor priority plugin controls access to queues
based on the user and bank information from the accounting database.

Queue Configuration
===================

A ``queues`` TOML table MAY define one or more named queues.  Each queue
SHALL be represented as a sub-table that MAY contain the following OPTIONAL
keys:

queues.NAME.requires
  (array of strings) Specify queue-specific resource property constraints
  (RFC 31) that SHALL be added to the jobspec ``system.constraints.properties``
  array of all jobs submitted to this queue.  If the jobspec already specifies
  property constraints, then the queue-specific properties SHALL be appended
  (logical and).

queues.NAME.policy
  (table) Specify policy fragments that apply only to this queue, using the
  form described in the previous section.  If the same policy appears in the
  top-level ``policy`` table  and a queue-specific ``policy`` table, the
  queue-specific value takes precedence for jobs submitted to that queue.

Initial Assignment of Job to Queue
----------------------------------

Job requests MAY specify a queue name at submission time by setting the
``system.queue`` jobspec attribute (RFC 14).  If a queue was not explicitly
named in the jobspec, and a default queue is defined, the queue SHALL be
assigned by before the jobtap ``job.validate`` callbacks are run.

Request Validation
------------------

A job request SHALL be rejected on submission if it names an unknown queue,
or if it is possible to determine that the job would exceed limits or violate
access policy of the assigned queue.

Administrative Tools
====================

A Flux command line tool SHALL provide the ability to enable/disable job
submission on each queue individually, or on all queues.

A Flux command line tool SHALL provide the ability to start/stop scheduling
on each queue individually, or on all queues.  When scheduling is stopped,
any pending ``alloc`` requests to the scheduler SHALL be canceled.

A Flux command line tool SHALL provide the ability to wait for a queue to
become empty, or for all queues to become empty.

A Flux command line tool SHALL provide the ability to wait for a queue to
become idle, or for all queues to become idle, where idle is defined as
containing no jobs in RUN or CLEANUP state.

Job Submission and Listing Tools
--------------------------------

Job submission and listing tools SHOULD NOT need to parse the ``queues``
TOML table.

The service providing data to the job listing tool SHOULD list pending and
running jobs in the default queue by default.  An option SHALL be provided
to request jobs in other queues by name, or all queues.

The job submission tools SHOULD leave the queue unset (thereby selecting
the default.  An option SHALL be provided to direct jobs to other
queues by name.
