.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_26.html

26/Job Dependency Specification
###############################

An extension to the canonical jobspec designed to express the dependencies
between one or more programs submitted to a Flux instance for execution.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_26.rst
  * - **Editor**
    - Stephen Herbein <herbein1@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_14`
- :doc:`spec_19`
- :doc:`spec_21`
- `OpenMP Specification <https://www.openmp.org/wp-content/uploads/OpenMP-API-Specification-5.0.pdf>`__
- `IETF RFC3986: Uniform Resource Identifier (URI) <https://datatracker.ietf.org/doc/html/rfc3986>`__

Goals
*****

-  Define how job dependencies are represented in jobspec.
-  Define how job dependencies are represented as command line arguments.
-  Describe simple, built-in job dependency schemes.
-  Plan for new dependency schemes to be added later.
-  Describe a mechanism for specifying dependencies as a directed acyclic graph
   (DAG).
-  Describe a mechanism for specifying more advanced, runtime dependencies.

Background
**********

RFC 21 defines a DEPEND state for jobs, which is exited once all job
dependencies have been satisfied, or a fatal exception has occurred.
The job must progress through DEPEND and PRIORITY states before reaching
SCHED state, therefore, dependency processing is independent of the scheduler.

When a job enters DEPEND state, job manager plugins post ``dependency-add``
events to the job eventlog, as described in RFC 21.  Plugins may add
dependencies based on explicit user requests in the jobspec, or based on
other implementation-dependent criteria.

As dependencies are satisfied, job manager plugins post ``dependency-remove``
events to the job eventlog, as described in RFC 21.  The job may leave DEPEND
state once all added dependencies have been removed.

Built-in job manager plugins handle the simple dependency schemes described
below.  Job manager plugins may be added to handle new schemes as needed.
Plugins may be self contained, or may outsource dependency processing to a
service outside of the job manager; for example, a separate broker module
or an entity that is not part of Flux.

Dependency Event Semantics
==========================

Dependency events SHALL only be posted to the job eventlog by job manager
plugins.

Dependency events SHALL be treated as matching when their ``description``
fields have the same value.

A dependency SHALL be considered satisfied when matching ``dependency-add``
and ``dependency-remove`` events have been posted.

Some special semantics for these events are needed to allow plugins
to reacquire their internal state when the job manager is restarted:

Attempts to post duplicate ``dependency-add`` events for unsatisfied
dependencies SHALL NOT raise a plugin error and SHALL NOT be posted.

Attempts to post duplicate ``dependency-add`` events for satisfied
dependencies SHALL raise a plugin error.

Representation
**************

A job dependency SHALL be represented as a JSON object with the following
REQUIRED keys:

scheme
  (string) name of the dependency scheme

value
  (string) semantics determined by the scheme.

A dependency object MAY contain additional OPTIONAL key-value pairs,
whose semantics are determined by the scheme.

in jobspec
==========

Each dependency requested by the user SHALL be represented as an element in
the jobspec ``attributes.system.dependencies`` array.  Each element SHALL
conform to the object definition above.

If job requests no dependencies, the key ``attributes.system.dependencies``
SHALL NOT be added to the jobspec.

on command line
===============

On the command line, a job dependency MAY be expressed in a compact, URI-like
form, with the first OPTIONAL key-value pair represented as a URI query
string, and additional OPTIONAL key-value pairs represented as URI query
options (``&`` or ``;`` delimited):

::

   scheme:value[?key=val[&key=val...]]

Examples:

-  ``afterany:ƒ2oLkTLb``
-  ``string:foo?type=out``
-  ``fluid:hungry-hippos-white-elephant``

This form SHOULD be translated by the command line tool to the object
form above before being shared with other parts of the system.

Simple Dependencies
*******************

The following dependency schemes are built-in.

after
=====

``value`` SHALL be interpreted as the antecedent jobid, in any valid
FLUID encoding from RFC 19.

The dependency SHALL be satisfied once the antecedent job enters RUN state
and posts a ``start`` event. If the antecedent job reaches INACTIVE state
without entering RUN state and posting a ``start`` event, a fatal exception
SHOULD be raised on the dependent job.

afterany
========

``value`` SHALL be interpreted as the antecedent jobid, in any valid
FLUID encoding from RFC 19.

The dependency SHALL be satisfied once the antecedent job enters INACTIVE
state, regardless of result.

afterok
=======

``value`` SHALL be interpreted as the antecedent jobid, in any valid
FLUID encoding from RFC 19.

The dependency SHALL be satisfied once the antecedent job enters INACTIVE
state, with a successful result.  If the antecedent job does not conclude
successfully, a fatal exception SHOULD be raised on the dependent job.

afternotok
==========

``value`` SHALL be interpreted as the antecedent jobid, in any valid
FLUID encoding from RFC 19.

The dependency SHALL be satisfied once the antecedent job enters INACTIVE
state, with an unsuccessful result.  If the antecedent job concludes
successfully, a fatal exception SHOULD be raised on the dependent job.

begin-time
==========

``value`` SHALL be interpreted as a floating point timestamp in seconds
since the UNIX epoch. The dependency SHALL be satisfied once the system
time reaches the specified timestamp.

OpenMP-style Dependencies
*************************

The ``string`` and ``fluid`` schemes are reserved for more sophisticated
symbolic and jobid based dependencies, inspired by the OpenMP specification.

string
======

``value`` SHALL be interpreted as a symbolic dependency name.

In addition, the following keys are REQUIRED for this scheme:

type
  (string) ``in``, ``out``, or ``inout`` as described below.

scope
  (string) ``user`` or ``global`` as described below.

fluid
=====

``value`` SHALL be interpreted as a jobid, in any valid FLUID encoding from
RFC 19.

type
  (string) ``in``, ``out``, or ``inout`` as described below.

scope
  (string) ``user`` or ``global`` as described below.

A dependency of this ``scheme`` with a ``type`` of ``out`` SHALL be generated
automatically for every job when OpenMP-style dependencies are active.

Type
====

The value of the ``type`` key SHALL be one of the following:

-  **out** This key only affects future submitted jobs. If the value of this key
   is the same as the value in an ``in`` or ``inout`` dependency of a future
   job within scope, then the future job will be a dependent job of the
   current generated job.

-  **in** If the value of this key is the same as the value in an ``out`` or ``inout``
   dependency of a previously submitted job within scope, then the
   generated job will be a dependent job of that previous job.

-  **inout** If the value of this key is the same as the value in an ``out`` or
   ``inout`` dependency of a previously submitted job within scope, then
   the generated job will be a dependent job of that previous job.

Planned future values for ``type`` include ``inoutset``, ``runtime``, and ``all``.

Scope
=====

The value of the ``scope`` key SHALL be one of the following:

-  **user** All jobs previously submitted by the user are contained within
   this scope. A user can create a dependency of any type within this scope.

-  **global** All jobs previously submitted are contained within this scope,
   subject to policy constraints. The instance owner can create a dependency
   of any type within this scope. A non-instance owner can only create a
   dependency with the type ``in`` within this scope.

Examples
========

Under the description above, the following are examples of fully compliant
dependency declarations.

Example 1
   Submitting a chain of jobs using ``inout``

Submitting multiple jobs with the following dependency definition will result in
the jobs running one after another.

.. literalinclude:: data/spec_26/example_1.yaml
   :language: yaml

Example 2
   Submitting job that depends on a system job

Submitting a job with the following dependency will result in the job running
after the completion of the system job with the FLUID of
``hungry-hippo-white-elephant``. One common use-case of this example is the case
of a large system dedicated access time (DAT). A DAT typically preempts any
running jobs. Users that do not want their jobs preempted will need to submit
their jobs with a dependency on the system DAT job.

.. literalinclude:: data/spec_26/example_2.yaml
   :language: yaml

Example 3
   Submitting a fan-out of jobs

A typical sub-component of a workflow DAG is a fan-out of jobs, consisting of a
single pre-processing job, many tasks, and a single post-processing job. These jobs
are represented as A, B, and C respectively in the DAG visualization below.

::

      A
     /|\
    B B B
     \|/
      C

The dependency definitions for each of the job types (i.e., A, B, C) in the
above DAG are provided below.

+---------------------------------------------------+---------------------------------------------------+----------------------------------------------------+
| Job A                                             | Job(s) B                                          | Job C                                              |
+===================================================+===================================================+====================================================+
| .. literalinclude:: data/spec_26/example_3_A.yaml | .. literalinclude:: data/spec_26/example_3_B.yaml | .. literalinclude:: data/spec_26/example_3_C.yaml  |
+---------------------------------------------------+---------------------------------------------------+----------------------------------------------------+
