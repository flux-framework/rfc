.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_25.html

25/Job Specification Version 1
##############################

A domain specific language based on YAML is defined to express the resource
requirements and other attributes of one or more programs submitted to a Flux
instance for execution. This RFC describes the version 1 of jobspec, which
represents a request to run exactly one program. This version is a simplified
version of the canonical jobspec format described in
:doc:`RFC 14 <spec_14>`.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_25.rst
  * - **Editor**
    - Stephen Herbein <herbein1@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_4`
- :doc:`spec_14`
- :doc:`spec_20`
- :doc:`spec_26`
- :doc:`spec_31`

Goals
*****

-  Express the resource requirements of a program to the scheduler.

-  Allow resource requirements to be expressed simply in terms of Nodes, CPUs,
   and GPUs.

-  Express program attributes such as arguments, run time, and
   task layout, to be considered by the execution service

Overview
********

This RFC describes the version 1 form of "jobspec", a domain specific language
based on YAML  [#f1]_. The version 1 of jobspec SHALL consist of
a single YAML document representing a reusable request to run
exactly one program. Hereafter, "jobspec" refers to the version 1
form, and "non-canonical jobspec" refers to the non-canonical form.

Jobspec Language Definition
***************************

A jobspec V1 YAML document SHALL consist of a dictionary
defining the resources, tasks and other attributes of a single
program. The dictionary MUST contain the keys ``resources``, ``tasks``,
``attributes``, and ``version``.

Each of the listed jobspec keys SHALL meet the form and requirements
listed in detail in the sections below. For reference, a ruleset for
compliant jobspec V1 is provided in the **Schema** section below.

Resources
=========

The value of the ``resources`` key SHALL be a strict list which MUST define either
``node`` or ``slot`` as the first and only resource. Each list element SHALL represent a
**resource vertex** (described below).

A resource vertex SHALL contain only the following keys:

-  type

-  count

-  unit

-  with

-  label

a ``node`` type resource vertex MAY also contain the following optional keys:

- exclusive

The definitions of ``unit``, ``with``, ``exclusive`` and ``label`` SHALL match
those found in RFC14. The others are redefined and simplified to mean the
following:

**type**
   The ``type`` key for a resource SHALL indicate the type of resource to be
   matched. In V1, only four resource types are valid: [``node``, ``slot``, ``core``,
   and ``gpu``]. ``slot`` types are described in the **Reserved Resource Types** section
   below.

**count**
   The ``count`` key SHALL indicate the desired number of
   resources matching the current vertex. The ``count`` SHALL be a single integer
   value representing a fixed count

V1-Specific Resource Graph Restrictions
---------------------------------------

In V1, the ``resources`` list MUST contain exactly one element, which MUST be
either ``node`` or ``slot``. Additionally, the resource graph MUST contain the
``core`` type.

In V1, there are also restrictions on which resources can have ``out`` edges to
other resources. Specifically, a ``node`` can have an out edge to a ``slot``, and a
``slot`` can have an ``out`` edge to a ``core``. If a ``slot`` has an ``out`` edge to a
``core``, it can also, optionally, have an ``out`` edge to a ``gpu`` as
well. Therefore, the complete enumeration of valid resource graphs in V1 is:

-  ``slot>core``

-  ``node>slot>core``

-  ``slot>(core,gpu)``

-  ``node>slot>(core,gpu)``

Tasks
=====

The ``tasks`` key SHALL be a strict list which MUST define exactly one task.
The list element SHALL be a dictionary representing a task to run as part of
the program. A task descriptor SHALL contain the following keys, whose
definitions SHALL match those provided in :doc:`RFC 14 <spec_14>`, with the
restriction in V1 that the ``count`` key does not support the ``per_resource``
key:

-  command

-  slot

-  count

The ``count`` key SHALL contain exactly one of the following keys:

-  per_slot

-  total

The definitions of these keys SHALL match those provided in
:doc:`RFC 14 <spec_14>`, with the following restrictions in V1: if ``per_slot``
is used, its value MUST be one, and if ``total`` is used its value MUST be less
than or equal to the ``count`` key of the associated slot and greater than or
equal to the number of allocated nodes (if no ``node`` resource vertex is
explicitly given in the jobspec, then this minimum value will depend on the
instance resource configuration and/or scheduler used).

Attributes
==========

The ``attributes`` key SHALL be a dictionary of dictionaries. The ``attributes``
dictionary MUST contain the ``system`` key and MAY contain the ``user`` key.
Common ``system`` keys are listed below, and their definitions can be found in
:doc:`RFC 14 <spec_14>`. Values MAY have any valid YAML type.

-  user

-  system

   -  duration

   -  preemptible-after

   -  environment

   -  cwd

   -  queue

   -  dependencies

   -  constraints

Most system attributes are optional, but the ``duration`` attribute is required in
jobspec V1.

Example Jobspec
***************

Under the description above, the following is an example of a fully compliant
version 1 jobspec. The example below declares a request for 4 "nodes"
each of which with 1 task slot consisting of 2 cores each, for a total
of 4 task slots. A single copy of the command ``app`` will be run on each
task slot for a total of 4 tasks.

.. literalinclude:: data/spec_25/example1.yaml
   :language: yaml

Basic Use Cases
===============

To implement basic resource manager functionality, the following use
cases SHALL be supported by the jobspec:

Section 1: Node-level Requests
------------------------------

The following "node-level" requests are all requests to start an instance,
i.e. run a single copy of ``flux start`` per allocated node. Many of these
requests are similar to existing resource manager batch job submission or
allocation requests, i.e. equivalent to ``oarsub``, ``qsub``, and ``salloc``.

Use Case 1.1
   Request nodes outside of a slot

Specific Example
   Request 4 nodes, each with 1 slot

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | Slurm                             | ``salloc -N4``                    |
   +-----------------------------------+-----------------------------------+
   | PBS                               | ``qsub -l nodes=4``               |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_25/use_case_1.1.yaml
      :language: yaml

Section 2: General Requests
---------------------------

The following use cases are more general and include more complex slot placement
and task counts.

Use Case 2.1
   Run N tasks across M nodes, unequal distribution

Specific Example
   Run 5 copies of ``hostname`` across 4 nodes,
   default distribution

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | Slurm                             | ``srun -n5 -N4 hostname``         |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_25/use_case_2.1.yaml
      :language: yaml

Use Case 2.2
   Run N tasks, Require M cores per task

Specific Example
   Run 10 copies of ``myapp``, require 2 cores per copy,
   for a total of 20 cores

Existing Equivalents
   +-----------------------------------+-----------------------------------+
   | Slurm                             | ``srun -n10 -c 2 myapp``          |
   +-----------------------------------+-----------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_25/use_case_2.2.yaml
      :language: yaml

Use Case 2.3
   Run N tasks, Require M cores and J gpus per task

Specific Example
   Run 10 copies of ``myapp``, require 2 cores and 1 gpu per copy,
   for a total of 20 cores and 10 gpus

Jobspec YAML
   .. literalinclude:: data/spec_25/use_case_2.3.yaml
      :language: yaml

Use Case 2.4
   Run N tasks across M nodes, each task with 1 core and 1 gpu

Specific Example
   Run 16 copies of ``myapp`` across 4 nodes, each copy with
   1 core and 1 gpu

Existing Equivalents
   +-----------------------------------+-------------------------------------------+
   | Slurm                             | ``srun -n16 -N4 --gpus-per-task=1 myapp`` |
   +-----------------------------------+-------------------------------------------+

Jobspec YAML
   .. literalinclude:: data/spec_25/use_case_2.4.yaml
      :language: yaml

Schema
******

A jobspec conforming to version 1 of the language definition SHALL
adhere to the following ruleset, described using JSON Schema [#f2]_.


.. literalinclude:: data/spec_25/schema.json
   :language: json

References
**********

.. [#f1] `YAML Ain’t Markup Language (YAML) Version 1.1 <https://yaml.org/spec/1.1/current.html>`__, O. Ben-Kiki, C. Evans, B. Ingerson, 2004.

.. [#f2] `JSON Schema: A Media Type for Describing JSON Documents <https://json-schema.org/draft/2020-12/json-schema-core>`__; H. Andrews; 2022
