.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_43.html

43/Job List Service
###################

The Flux Job List Service provides read-only summary information for jobs.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_43.rst
  * - **Editor**
    - Albert Chu <chu11@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_18`
- :doc:`spec_20`
- :doc:`spec_21`
- :doc:`spec_25`
- :doc:`spec_26`
- :doc:`spec_27`
- :doc:`spec_29`
- :doc:`spec_31`
- :doc:`spec_41`

Background
**********

The job list service provides a simple job query service that collates
information from several sources, including the job info service
described in RFC 41.  Some use cases include:

- See which jobs are pending, running, or inactive
- See what jobs are running on specific nodes
- Get general information about a job, such as a job's exit code
- See the order in which jobs were submitted
- See how many jobs are pending in the queue before a specific one

Goals
*****

- Provide read-only access to job information

- limit guest access to sensitive job information such as job stdout.

- Hide the complexity of parsing or collating data from multiple sources for commonly accessed information.

- Provide ways to query jobs callers are interested in.

Implementation
**************

The job list service SHALL provide callers the ability to request specific job attributes.  See :ref:`spec_43_job_attributes` below for details.

The job list service SHALL provide a RFC 31 constraint syntax for filtering jobs.  See :ref:`spec_43_constraint_operators` below for details.

.. _spec_43_job_attributes:

Job Attributes
==============

The job list service SHALL support the following attributes.

.. list-table::
   :header-rows: 1

   * - Attribute
     - Description
     - Value Encoding
   * - ``id``
     - job id
     - integer
   * - ``userid``
     - userid of job submitter
     - integer
   * - ``urgency``
     - job urgency
     - integer
   * - ``priority``
     - job priority
     - integer
   * - ``t_submit``
     - time job was submitted
     - real
   * - ``t_depend``
     - time job entered depend state
     - real
   * - ``t_run``
     - time job entered run state
     - real
   * - ``t_cleanup``
     - time job entered cleanup state
     - real
   * - ``t_inactive``
     - time job entered inactive state
     - real
   * - ``state``
     - current job state
     - integer
   * - ``name``
     - job name
     - string
   * - ``cwd``
     - job current working directory
     - string
   * - ``queue``
     - job queue
     - string
   * - ``project``
     - job project
     - string
   * - ``bank``
     - job bank
     - string
   * - ``ntasks``
     - job task count
     - integer
   * - ``ncores``
     - job core count
     - integer
   * - ``nnodes``
     - job node count
     - integer
   * - ``ranks``
     - ranks a job ran on
     - integer
   * - ``nodelist``
     - nodes assigned to a job in RFC 29 Hostlist format
     - string
   * - ``duration``
     - job duration in seconds
     - real
   * - ``expiration``
     - time job was marked to expire
     - real
   * - ``success``
     - true if job was successful
     - boolean
   * - ``result``
     - integer indicating job success or failure type
     - integer
   * - ``waitstatus``
     - status of job as returned by waitpid(2)
     - integer
   * - ``exception_occurred``
     - true if exception occurred
     - boolean
   * - ``exception_type``
     - if exception occurred, exception type
     - string
   * - ``exception_severity``
     - if exception occurred, exception severity
     - integer
   * - ``exception_note``
     - if exception occurred, exception note
     - string
   * - ``annotations``
     - annotations as described in RFC 27
     - object
   * - ``dependencies``
     - current job dependencies
     - array of string

Job attributes SHALL be returned via an object where the keys are the requested job attributes.  The values are the attribute values, each encoded as described in the above table.

The attribute ``id`` SHALL always be returned for each job.  Every other attribute is optional.

Not all job attributes are available for a job.  Many attributes are dependent on job state, job submission information, system configuration, or other conditions.  For example:

- a job that is pending (i.e. not yet running) does not yet have any resources to run on.  Therefore, ``ranks`` or ``nodelist`` cannot yet be set.  Similarly, attributes such as ``success`` or ``result`` cannot yet be determined.  A timestamp like ``t_run`` would not yet have a value.
- a job submitted without dependencies will never have ``dependencies`` set
- a job cannot belong in a ``queue`` on a system without a job queue
- ``exception_type`` will only exist if ``exception_occurred`` is true

If an attribute has not been set for a job, it SHALL NOT be returned in the returned data object.

.. _spec_43_constraint_operators:

Constraint Operators
====================

Using the constraint syntax described by RFC 31, jobs can be filtered
based on the following constraint operators.

``userid``
    Designate one or more userids (*integer*) and match jobs submitted by those userids.

``name``
    Designate one or more job names (*string*) and match jobs with those job names.

``queue``
    Designate one or more queues (*string*) and match jobs submitted to those job queues.

``states``
    Designate one or more job states (*string* or *integer*) and match jobs in those job states.  Both bitmasks (including multiple states) and string names of the states SHALL be accepted.

``results``
    Designate one or more job results (*string* or *integer*) and match jobs with those results.  Both bitmasks (including multiple results) and string names of the results SHALL be accepted.

``hostlist``
    Designate one or more nodes in RFC 29 Hostlist format (*string*) and match jobs assigned to those nodes.  The job list module MAY limit the number of entries in a hostlist constraint to prevent long constraint match times.

``ranks``
    Designate one or more broker ranks in RFC 22 Idset form (*string*) and match jobs that were assigned to one or more of those ranks. The job list module MAY limit the number of entries in a ranks constraint to prevent long constraint match times.

``t_submit``, ``t_depend``, ``t_run``, ``t_cleanup``, ``t_inactive``
    Designate one timestamp with a REQUIRED prefixed comparison operator (*string*).  The accepted comparison operators SHALL be `>`, `<`, `>=`, and `<=`, for greater than, less than, greater than or equal, or less than or equal. A timestamp operator SHALL match jobs where the respective timestamp matches against the provided timestamp.

``or``
    Logical or of one or more constraint objects.

``and``
    Logical and of one or more constraint objects..

``not``
   Logical negation of the and of one or more constraint objects.

The following are several constraints examples.

Filter jobs that belong to userid 42 or 43

.. code:: json

   { "userid": [ 42, 43 ] }

Filter jobs that were not submitted to job queue "foobar"

.. code:: json

   { "not": [ { "queue": [ "foobar" ] } ] }

Filter jobs that are pending.

.. code:: json

   { "states": [ "depend", "priority", "sched" ] }

Filter jobs that belong to userid 42 and were submitted after January 1, 2000.

.. code:: json

   { "and": [ { "userid": [ 42 ] }, { "t_submit": [ ">946713600.0" ] } ] }

In order to limit the potential for a constraint to cause a denial of service (DoS) or long job list service hang, a comparison limit MAY be configured.  Every "check" against a job is considered a comparison.  In the last example above, the constraint is looking for all jobs belonging to userid 42 and submitted after January 1, 2000.  It will consume at most 2 comparisons for each job.  The ``userid`` check will always consume 1 comparison and the submission time will consume a comparison if the ``userid`` check passes.

After the maximum number of comparisons is consumed, an error SHALL be returned to the caller.  The caller MAY decrease their search footprint by limiting their search using other inputs in the job list request or making tighter constraints.  For example, take following two constraints:

.. code:: json

   { "and": [ { "queue": [ "foobar" ] }, { "userid": [ 42 ] } ] }

.. code:: json

   { "and": [ { "userid": [ 42 ] }, { "queue": [ "foobar" ] } ] }

In these examples the caller wants to filter jobs submitted to the queue foobar and submitted by userid 42.  The only difference is the order of the checks.  If "foobar" is the most common queue in the system (i.e. the check for queue "foobar" typically succeeds) and ``userid`` is not the most common user in the system (i.e. the check for userid "42" typically fails), the latter constraint consumes fewer comparisons.

List
====

The :program:`job-list.list` RPC fetches a list of jobs.

The list of jobs shall be filtered in the following order.

- pending jobs
- running jobs
- inactive jobs

Pending jobs are returned ordered by priority (higher priority first),
running jobs ordered by start time (most recent first), and inactive
jobs ordered by completion (most recently finished first)

The RPC payloads are defined as follows:

.. object:: job-info.lookup request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: max_entries

    (*integer*, REQUIRED) Indicate the maximum number of entries to be
    returned.  Specify 0 for no limit.

  .. object:: attrs

    (*array of string*, REQUIRED) List of attributes to return.  The
    special job attribute ``all`` SHALL allow a caller to request all job
    attributes for a job.

  .. object:: since

    (*real*, OPTIONAL) Limit output to jobs that have been active
    since a given time.  If not specified, all jobs are considered.

  .. object:: constraint

    (*object*, OPTIONAL) Limit output to jobs that match a constraint
    object as described in RFC 31.  See :ref:`spec_43_constraint_operators` for
    legal job list constraint operators.  If not specified, match all
    jobs.

.. object:: job-info.lookup response

  The response SHALL consist of a JSON object with the following keys:

  .. object:: jobs

    (*array of objects*, REQUIRED) A list of the jobs returned from
    the request.  Each object will contain the requested attributes in
    an object described in :ref:`spec_43_job_attributes`.

List ID
=======

The :program:`job-list.list-id` RPC fetches job attributes for a specific job ID.

The RPC payloads are defined as follows:

.. object:: job-list.list-id request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: id

    (*integer*, REQUIRED) The job id.

  .. object:: attrs

    (*array of string*, REQUIRED) List of attributes to return.  The
    special job attribute ``all`` SHALL allow a caller to request all job
    attributes for a job.

  .. object:: state

    (*integer*, OPTIONAL) Specify optional job state to wait for job
    to reach, before returning job data.  This may be useful so that
    state specific job attributes will be available before returning.

.. object:: job-list.list-id response

  The response SHALL consist of a JSON object with the following keys:

  .. object:: job

    (*object*, REQUIRED) The job information from the request.  The
    returned object will contain the requested attributes in an object
    described in :ref:`spec_43_job_attributes`.

List Attributes
===============

The :program:`job-list.list-attrs` RPC returns a list of all job attributes
that can be returned.

The RPC payloads are defined as follows:

.. object:: job-list.list-attrs request

  No keys are recognized for the request.

.. object:: job-list.list-attrs response

  The response SHALL consist of a JSON object with the following keys:

  .. object:: attrs

    (*array of string*, REQUIRED) List of attributes

Example
=======

job-list.list request
---------------------

.. code:: json

  {
    "max_entries": 2,
    "attrs": ["userid", "name"],
    "constraint": { "states": [ "run" ] }
  }

job-list.list response
----------------------

.. code:: json

  {
    "jobs": [
      {
        "id": 120762400768,
        "userid": 42,
        "name": "foo.sh"
      },
      {
        "id": 61488496640,
        "userid": 42,
        "name": "bar.sh"
      }
    ]
  }
