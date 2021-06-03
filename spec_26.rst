.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_26.html

26/Job Dependency Specification
===============================

An extension to the canonical jobspec designed to express the dependencies
between one or more programs submitted to a Flux instance for execution.

-  Name: github.com/flux-framework/rfc/spec_26.rst
-  Editor: Stephen Herbein <herbein1@llnl.gov>
-  State: raw

Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.

Related Standards
-----------------

-  :doc:`14/Canonical Job Specification <spec_14>`
-  :doc:`19/Flux Locally Unique ID <spec_19>`
-  `OpenMP Specification <https://www.openmp.org/wp-content/uploads/OpenMP-API-Specification-5.0.pdf>`__
-  `IETF RFC3986: Uniform Resource Identifier (URI) <https://tools.ietf.org/html/rfc3986>`__


Goals
-----

-  Define how job dependencies are represented in jobspec.
-  Define how job dependencies are represented as command line arguments.
-  Describe simple, built-in job dependency schemes.
-  Plan for new dependency schemes to be added later.
-  Describe a mechanism for specifying dependencies as a directed acyclic graph
   (DAG).
-  Describe a mechanism for specifying more advanced, runtime dependencies.

Job Dependency Definition
-------------------------

A dependency SHALL be a dictionary containing the following keys (whose
definitions are detailed in the sections below):

-  **type**
-  **scope**
-  **scheme**
-  **value**

Type
~~~~

The value of the ``type`` key SHALL be one of the following (the semantics of
which are inspired by the OpenMP specification):

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
~~~~~

The value of the ``scope`` key SHALL be one of the following:

-  **user** All jobs previously submitted by the user are contained within
   this scope. A user can create a dependency of any type within this scope.

-  **global** All jobs previously submitted are contained within this scope,
   subject to policy constraints. The instance owner can create a dependency
   of any type within this scope. A non-instance owner can only create a
   dependency with the type ``in`` within this scope.

Scheme
~~~~~~

The value of the ``scheme`` key SHALL be a string. Valid values MAY be but are
not limited to the following:

-  **string** The ``value`` is to be interpreted as a string literal.

-  **fluid** The ``value`` is to be interpreted as a Flux Locally Unique ID. A
   dependency of this ``scheme`` with a ``type`` of ``out`` SHALL be generated
   automatically for every job by the job dependency system.

Value
~~~~~

The value of the ``value`` key SHALL be a string, whose semantics are
determined by the ``scheme``.

Shorthand
---------

For convenience at the command line, dependencies MAY be formatted as a
`Uniform Resource Identifier (URI) <https://tools.ietf.org/html/rfc3986>`__ and
then expanded into the dictionary format described above. It is left up to each
implementation as to which URIs to support, the URIs' semantics, default values,
and what to do when an unsupported URI is encountered. Some example URIs
include:

-  ``string:foo``
-  ``string:foo?type=out``
-  ``fluid:hungry-hippos-white-elephant``

Examples
--------

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
