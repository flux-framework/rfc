
14/Canonical Job Specification
==============================

A domain specific language based on YAML is defined to express the
resource requirements and other attributes of one or more programs
submitted to a Flux instance for execution. This RFC describes the
canonical jobspec form, which represents a request to run exactly
one program.

-  Name: github.com/flux-framework/rfc/spec_14.adoc

-  Editor: Tom Scogland <scogland1@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`4/Flux Resource Model <spec_4>`

-  :doc:`8/Flux Task and Program Execution Services <spec_8>`

-  :doc:`20/Resource Set Specification Version 1 <spec_20>`

-  `26/Job Dependency Specification <spec_26.rst>`__


Goals
-----

-  Express the resource requirements of a program to the scheduler.

-  Allow graph-oriented resource requirements to be expressed.

-  Express program attributes such as arguments, run time, and
   task layout, to be considered by the program execution service (RFC 12)

-  Express dependencies relative to other programs executing within
   the same Flux instance.

-  Emphasize expressivity over simplicity, as this canonical form
   may be generated from other user-friendly forms or interfaces.

-  Facilitate reproducible runs.

-  Promote sharing and reuse of jobspec.


Overview
--------

This RFC describes the canonical form of "jobspec", a domain specific
language based on YAML  [#f1]_. The canonical jobspec SHALL consist of
a single YAML document representing a reusable request to run
exactly one program. Hereafter, "jobspec" refers to the canonical
form, and "non-canonical jobspec" refers to the non-canonical form.

Non-canonical jobspec SHALL be decomposed into jobspec before
it is enqueued for the scheduler and program execution service.

User facing tools MAY generate jobspec from non-canonical jobspec,
or other sources. Such tools MAY:

-  generate a batch of dependent jobspecs representing a scientific workflow

-  generate a stream of jobspecs representing a steered parameter study

-  convert simulation parameters into jobspec containing computed
   resource requirements, etc.

-  convert command line arguments to jobspec, e.g. "flux mpirun"


Jobspec and Program Life Cycle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The jobspec SHALL be submitted to a job submission service. Malformed
jobspec SHALL be immediately rejected by the job submission service.
A stack of plugins SHALL test jobspec against site or user defined
criteria, and on failure, MAY reject the jobspec, or MAY warn the user
and continue on. The job submission service SHALL enqueue the jobspec
for consideration by the scheduler.

The scheduler SHALL consider each enqueued jobspec in the context of its
dependencies and the pool of available resources. When the scheduler
chooses to execute a job, it allocates resources, associates them
with the jobspec, and notifies the program execution service to start
the program(s).

The program execution service, described in RFC 12, launches the program(s).
Task slots, containment, and task layout SHALL be created within the
allocated resources as described by the jobspec, or if that is not
possible, the job SHALL enter a failed state and resources SHALL
be returned to the scheduler.

Once a job is retired, the jobspec SHALL be retained as part of
its provenance record.


Resource Matching
~~~~~~~~~~~~~~~~~

Resources are represented as hierarchies or graphs, as described in RFC 4.

FIXME: describe how Flux hierarchical resource representation affects
jobspec design.


Terminology
~~~~~~~~~~~

FIXME: Fill in


Jobspec Language Definition
---------------------------

A canonical jobspec YAML document SHALL consist of a dictionary
defining the resources, tasks and other attributes of a single
program. The dictionary MUST contain the keys ``resources``, ``tasks``,
``attributes``, and ``version``.

Each of the listed jobspec keys SHALL meet the form and requirements
listed in detail in the sections below. For reference, a ruleset for
compliant canonical jobspec is provided in the **Schema** section below.


Resources
~~~~~~~~~

The value of the ``resources`` key SHALL be a strict list which MUST
define at least one resource. Each list element SHALL represent a
**resource vertex** or resource descriptor object as a dictionary
(described below). The list of resources defined under the ``resources``
key SHALL represent a composite resource request for the program
defined in the jobspec.

A resource vertex SHALL contain the following keys:

**type**
   The ``type`` key for a resource SHALL indicate the type of resource to
   be matched. Some type names MAY be reserved for use in the jobspec
   language itself. The currently reserved type is ``slot``, used to
   define **task slots**. Reserved types are described in the
   **Reserved Resource Types** section below.

**count**
   The ``count`` key SHALL indicate the desired number or range of
   resources matching the current vertex. The ``count`` SHALL have one
   of two possible values: either a single integer value representing
   a fixed count, or a dictionary which SHALL contain the following keys:

   **min**
      The minimum required count or amount of this resource

   and additionally MAY contain the following keys:

   **max**
      The maximum required count or amount of this resource

   **operator**
      An operator applied between ``min`` and ``max`` which
      returns the next acceptable value

   **operand**
      The operand used in conjunction with ``operator``

   The default value for ``max`` SHALL be *infinite*, therefore a ``count``
   which specifies only the ``min`` key SHALL be considered a request for
   *at least* that number of a resource, and the scheduler SHALL generate
   the *R* that contains the maximum number of the resource that is
   available and subject to the operator and operand. By contrast,
   if a fixed count is given to the ``count`` key, the scheduler SHALL
   match any resource that contains *at least* ``count`` of the resource,
   but its *R* SHALL contain exactly ``count`` of the resource
   (potentially leaving excess resources unutilized).

A resource vertex MAY additionally contain one or more of the
following keys

**unit**
   The ``unit`` key, if supplied, SHALL have a string value indicating
   the chosen units applied to the ``count`` value or values.

**exclusive**
   The ``exclusive`` key SHALL be a boolean indicating, when true, that
   the current resource is requested to be allocated exclusively to
   the current program. If unset, the default value for ``exclusive`` SHALL
   be ``false`` for vertices that are not within a task slot. The default
   value for ``exclusive`` SHALL be ``true`` for task slots (``type: slot``)
   and their associated resources.

**with**
   The ``with`` key SHALL indicate an edge of type ``out`` from this resource
   vertex to another resource. Therefore, the value of the ``with`` key
   SHALL be a dictionary conforming to the resource vertex specification.

**label**
   The ``label`` key SHALL be a string that may be used to reference this
   resource vertex from other locations within the same jobspec. ``label``
   SHALL be local to the namespace of the current jobspec, and each ``label``
   in the current jobspec must be unique. ``label`` SHALL be mandatory in
   resource vertices of type ``slot``.

**id**
   The value of the ``id`` key SHALL be a string indicating a set of
   matching resource identifiers.


Reserved Resource Types
^^^^^^^^^^^^^^^^^^^^^^^

**slot**
   A resource type of ``type: slot`` SHALL indicate a grouping
   of resources into a named **task slot**. A ``slot`` SHALL be a valid
   resource spec including a ``label`` key, the value of which may be used
   to reference the named task slot during tasks definition. The ``label``
   provided SHALL be local to the namespace of the current jobspec.

   A task slot SHALL have at least one edge specified using ``with:``, and
   the resources associated with a slot SHALL be exclusively allocated
   to the program described in the jobspec, unless otherwise specified
   in the ``exclusive`` field of the associated resource.


Tasks
~~~~~

The value of the ``tasks`` key SHALL be a strict list which MUST
define at least one task. Each list element SHALL be a dictionary
representing a task or tasks to run as part of the program. A task
descriptor SHALL contain the following keys:

**command**
   The value of the ``command`` key SHALL be a list representing an
   executable and its arguments.

**slot**
   The value of the ``slot`` key SHALL match a ``label`` of a resource vertex
   of type ``slot``. It is used to indicate the **task slot**
   on which this task or tasks shall be contained and executed. The
   number of tasks executed per task slot SHALL be a function of the
   number of resource slots and total number of tasks requested to execute.

**count**
   The value of the ``count`` key SHALL be a dictionary supporting at
   least the keys ``per_slot``, ``per_resource``, and ``total``, with other keys
   reserved for future or site-specific extensions.

   **per_slot**
      The value of ``per_slot`` SHALL be a number indicating the number
      of tasks to execute per task slot allocated to the program.

   **per_resource**
      The value of ``per_resource`` SHALL be a dictionary which
      SHALL contain the following keys:

      -  **type** The value of the ``type`` key SHALL be a resource type explicitly
         declared in the associated task’s slot.

      -  **count** The value of the ``count`` key SHALL be a number indicating the number
         of tasks to execute per resource of type ``type`` occurring in the task’s
         slot.

   **total**
      The value of the ``total`` field SHALL indicate the total number of
      tasks to be run across all task slots, possibly oversubscribed.

**attributes**
   The ``attributes`` key SHALL be a free-form dictionary of keys which may
   be used for platform independent or optional extensions.

**distribution**
   The value of the ``distribution`` key SHALL be a string, which MAY
   be used as input to the launcher’s algorithm for task placement and
   layout among task slots.


Attributes
~~~~~~~~~~

The value of the ``attributes`` key SHALL be a dictionary of dictionaries.
The ``attributes`` dictionary MAY contain one or both of the following keys
which, if present, must have values. Values MAY have any valid YAML type.

**user**
   Attributes in the ``user`` dictionary are unrestricted, and may be used
   as the application demands. Flux may provide additional tools that can
   identify jobs based on ``user`` attributes.

**system**
   Attributes in the ``system`` dictionary are additional parameters to
   a Flux instance that affect program execution, scheduling, etc. All
   attributes in ``system`` are reserved words, however unrecognized
   words SHALL trigger no more than a warning. This permits jobspec
   reuse between multiple flux instances which may be configured differently
   and recognize different sets of attributes.

   Most system attributes are optional. Flux modules SHALL provide
   reasonable defaults for any system attributes that they recognize when
   at all possible.

Some common system attributes are:

**duration**
   The value of the ``duration`` attribute is a floating-point number greater than
   or equal to zero representing time span in seconds. A ``duration`` of 0 SHALL be
   interpreted as "unlimited" or "not set" by the system. The scheduler will make
   an effort to allocate the requested resources for the number of seconds
   specified in ``duration``.

**environment**
   The value of the ``environment`` attribute is a dictionary containing the names
   and values of environment variables that should be set (or unset) when spawning
   tasks. For each entry in the ``environment`` dictionary, the ``key`` is a string
   representing the environment variable name and the ``value`` is a string
   representing the environment variable value to set. A ``null`` ``value``
   represents unsetting the environment variable given by ``key``. The values
   provided here can be overridden per-rank by providing the
   ``attributes.environment`` dictionary under the target task.

**cwd**
   The value of the ``cwd`` attribute is a string containing the absolute
   path to the current working directory to use when spawning the task.

**dependencies**
   The value of the ``dependencies`` attribute SHALL be a
   list of dictionaries following the format specified in RFC 26.

**job**
   The ``job`` attribute is an optional dictionary containing job
   metadata. This metadata may be used for searching and filtering of
   jobs. Every ``value`` in the dictionary must be a string. The
   application is free to create keys of any name, however the following
   are reserved for special use:

   **name**
      The ``name`` key contains the name of the job. The default name of a
      job is the first argument of the command run by the user, or it can be
      set by the user to an arbitrary value.

**shell**
   The ``shell`` attribute is an optional dictionary containing job shell
   metadata, such as configuration options. The application is free to
   create keys of any name, however the following are reserved for
   special use:

   **options**
      The ``options`` key is a dictionary containing configuration options
      for the job shell. A job shell and its plugins are free to define
      what keys and values should go into ``options``.


Example Jobspec
~~~~~~~~~~~~~~~

Under the description above, the following is an example of a fully compliant
canonical jobspec. The example below declares a request for 4 "nodes"
each of which with 1 task slot consisting of 2 cores each, for a total
of 4 task slots. A single copy of the command ``app`` will be run on each
task slot for a total of 4 tasks.

.. literalinclude:: data/spec_14/example1.yaml
   :language: yaml

Another example, running one task on each of four nodes.

.. literalinclude:: data/spec_14/example2.yaml
   :language: yaml


Schema
~~~~~~

A jobspec conforming to the canonical language definition SHALL
adhere to the following ruleset, described using JSON Schema  [#f2]_.

.. literalinclude:: data/spec_14/schema.json
   :language: json



Basic Use Cases
---------------

To implement basic resource manager functionality, the following use
cases SHALL be supported by the jobspec:


Section 1: Node-level Requests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following "node-level" requests are all requests to start an instance,
i.e. run a single copy of ``flux start`` per allocated node. Many of these
requests are similar to existing resource manager batch job submission or
allocation requests, i.e. equivalent to ``oarsub``, ``qsub``, and ``salloc``.

Use Case 1.1
   Request Single Resource with Count

Specific Example
   Request 4 nodes

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | Slurm                             | ``salloc -N4``                    |
   +-----------------------------------+-----------------------------------+
   | PBS                               | ``qsub -l nodes=4``               |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_1.1.yaml
      :language: yaml

Use Case 1.2
   Request a range of a type of resource

Specific Example
   Request between 3 and 30 nodes

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | Slurm                             | ``salloc -N3-30``                 |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_1.2.yaml
      :language: yaml

Use Case 1.3
   Request M nodes with a minimum number of sockets per node
   and cores per socket

Specific Example
   Request 4 nodes with at least 2 sockets each,
   and 4 cores per socket

Existing Equivalents
   +-----------------------------------+--------------------------------------------------------+
   | Slurm (a)                         | ``srun -N4 --sockets-per-node=2 --cores-per-socket=4`` |
   +-----------------------------------+--------------------------------------------------------+
   | Slurm (b)                         | ``srun -N4 -B '2:4:*'``                                |
   +-----------------------------------+--------------------------------------------------------+
   | OAR                               | ``oarsub -l nodes=4/sockets=2/cores=4``                |
   +-----------------------------------+--------------------------------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_1.3.yaml
      :language: yaml

Use Case 1.4
   Exclusively allocate nodes, while constraining cores and
   sockets.

Specific Example
   Request an **exclusive** allocation of 4 nodes that have at
   least two sockets and 4 cores per socket:

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_1.4.yaml
      :language: yaml

Use Case 1.5
   Complex example from OAR

Specific Example
      ask for 1 core on 2 nodes on the same cluster with 4096 GB of memory
      and Infiniband 10G + 1 cpu on 2 nodes on the same switch with bicore
      processors for a walltime of 4 hours

      — 
      http://oar.imag.fr/docs/2.5/user/usecases.html#mixing-every-together

Existing Equivalents
   +-----------------------------------+-----------------------------------------------------------------------------------------------------------------------------+
   | OAR                               | ``oarsub -I -l "{memnode=4096 and ib10g='YES'}/cluster=1/nodes=2/core=1+{nbcore=2}/switch=1/nodes=2/cpu=1,walltime=4:0:0"`` |
   +-----------------------------------+-----------------------------------------------------------------------------------------------------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_1.5.yaml
      :language: yaml

Use Case 1.6
   Request resources across multiple clusters

Specific Example
   Ask for 30 cores on 2 clusters (total = 60 cores), with 1 flux broker launched per node

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_1.6.yaml
      :language: yaml

Use Case 1.7
   Request N cores across M switches

Specific Example
   Request 3 cores across 3 switches, with 1 flux broker launched per node

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | OAR                               | ``oarsub -I -l /switch=3/core=1`` |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_1.7.yaml
      :language: yaml

Section 2: General Requests
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following use cases are more general and include more complex slot placement
and task counts.

Use Case 2.1
   Run N tasks across M nodes

Specific Example
   Run ``hostname`` 20 times on 4 nodes, 5 per node

Existing Equivalents
   +-----------------------------------+-------------------------------------------+
   | Slurm                             | ``srun -N4 -n20 hostname`` or             |
   |                                   | ``srun -N4 --ntasks-per-node=5 hostname`` |
   +-----------------------------------+-------------------------------------------+
   | PBS                               | ``qsub -l nodes=4,mppnppn=5``             |
   +-----------------------------------+-------------------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_2.1.yaml
      :language: yaml

Use Case 2.2
   Run N tasks across M nodes, unequal distribution

Specific Example
   Run 5 copies of ``hostname`` across 4 nodes,
   default distribution

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | Slurm                             | ``srun -n5 -N4 hostname``         |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_2.2.yaml
      :language: yaml

Use Case 2.3
   Run N tasks, Require M cores per task

Specific Example
   Run 10 copies of ``myapp``, require 2 cores per copy,
   for a total of 20 cores

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | Slurm                             | ``srun -n10 -c 2 myapp``          |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_2.3.yaml
      :language: yaml

Use Case 2.4
   Run different binaries with differing resource
   requirements as single program

Specific Example
   11 tasks, one node, the first 10 tasks each using one core and 4G of RAM for
   ``read-db``, the last task using 6 cores and 24G of RAM for ``db``

Existing Equivalents
   None Known

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_2.4.yaml
      :language: yaml

Use Case 2.5
   Run command requesting minimum amount of RAM per core

Specific Example
   Run 10 copies of ``app`` across 10 cores with at least 2GB per core

Existing Equivalents
   +-----------------------------------+---------------------------------------+
   | Slurm                             | ``srun -n 10 --mem-per-cpu=2048 app`` |
   +-----------------------------------+---------------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_2.5.yaml
      :language: yaml

Use Case 2.6
   Run N copies of a command with minimum amount of RAM per node

Specific Example
   Run 10 copies of ``app`` across 2 nodes with at least 4GB per node

Existing Equivalents
   +-----------------------------------+-----------------------------------------------------------------------------------------------------+
   | Slurm                             | ``srun -n10 -N2 --mem=4096 app``                                                                    |
   +-----------------------------------+-----------------------------------------------------------------------------------------------------+
   | OAR                               | ``oarsub -p memnode=4096 -l nodes=2 "taktuk -c oarsh -f $OAR_FILE_NODES broadcast exec [app]"``     |
   +-----------------------------------+-----------------------------------------------------------------------------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_2.6.yaml
      :language: yaml

Use Case 2.7
   Override the global environment

Specific Example
   Run two different tasks, one with the global environment and one with an
   overridden environment (i.e., unset FOO and set BAR=2).

Jobspec YAML
   .. literalinclude:: data/spec_14/use_case_2.7.yaml
      :language: yaml

Use Case 2.8
   Specify dependencies

Specific Example
   Depend on two previously submitted jobs. The first job’s
   Flux ID (fluid) is known (``hungry-hippo-white-elephant``). The second job’s
   fluid is not known but its ``out`` dependency (``foo``) is known. Also provide an
   ``out`` dependency (``bar``) that other jobs can depend on.

Jobspec YAML
   .. code:: yaml

      version: 999
      resources:
        - type: slot
          count: 1
          label: default
          with:
            - type: node
              count: 1
      tasks:
        - command: [ "flux", "start" ]
          slot: default
          count:
            per_slot: 1
      attributes:
        system:
          duration: 3600.
          cwd: "/home/flux"
          dependencies:
            - type: in
              scope: user
              scheme: fluid
              value: hungry-hippo-white-elephant
            - type: in
              scope: user
              scheme: string
              value: foo
            - type: out
              scope: user
              scheme: string
              value: bar

.. [#f1] `YAML Ain’t Markup Language (YAML) Version 1.1 <http://yaml.org/spec/1.1/current.html>`__, O. Ben-Kiki, C. Evans, B. Ingerson, 2004.

.. [#f2] `JSON Schema: A Media Type for Describing JSON Documents <https://json-schema.org/latest/json-schema-core.html>`__; H. Andrews; 2018
