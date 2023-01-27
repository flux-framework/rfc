.. Copyright 2020 Lawrence Livermore National Security, LLC
   (c.f. AUTHORS, NOTICE.LLNS, COPYING)

   SPDX-License-Identifier: (LGPL-3.0)

.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/index.html

Flux RFC Index
==============

This is the Flux RFC project.

We collect specifications for APIs, file formats, wire protocols, and
processes.

Active RFC Documents
--------------------

:doc:`1/C4.1 - Collective Code Construction Contract <spec_1>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Collective Code Construction Contract (C4.1) is an evolution of
the github.com Fork + Pull Model, aimed at providing an optimal
collaboration model for free software projects.

:doc:`2/Flux Licensing and Collaboration Guidelines <spec_2>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Flux framework is a family of projects used to build
site-customized resource management systems for High Performance
Computing (HPC) data centers. This document specifies licensing and
collaboration guidelines for Flux projects.

:doc:`3/Flux Message Protocol <spec_3>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the format of Flux messages, Version 1.

:doc:`4/Flux Resource Model <spec_4>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Flux Resource Model describes the conceptual model used for
resources within the Flux framework.

:doc:`5/Flux Broker Modules <spec_5>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the broker extension modules used to
implement Flux services.

:doc:`6/Flux Remote Procedure Call Protocol <spec_6>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes how Flux Remote Procedure Call (RPC) is
built on top of Flux request and response messages.

:doc:`7/Flux Coding Style Guide <spec_7>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification presents the recommended standards when
contributing C code to the Flux code base.

:doc:`8/Flux Task and Program Execution Services <spec_8>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A core service of Flux is to launch, monitor, and handle I/O for
distributed sets of tasks in order to execute a parallel workload. A
Flux workload can include further instances of Flux, to arbitrary
recursive depth. The goal of this RFC is to specify in detail the
services required to execute a Flux workload.

:doc:`9/Distributed Communication and Synchronization Best Practices <spec_9>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Establishes best practices, preferred patterns and anti-patterns for
distributed services in the flux framework.

:doc:`10/Content Storage <spec_10>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the Flux content storage service and
the messages used to access it.

:doc:`11/Key Value Store Tree Object Format v1 <spec_11>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Flux Key Value Store (KVS) implements hierarchical key
namespaces layered atop the content storage service described in
RFC 10. Namespaces are organized as hash trees of content-addressed
tree objects and values. This specification defines the version 1
format of key value store tree objects.

:doc:`12/Flux Security Architecture <spec_12>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This document describes the mechanisms used to secure Flux instances
against unauthorized access and prevent privilege escalation and
other attacks, while ensuring programs run with appropriate user
credentials and are contained within their set of allocated
resources.

:doc:`13/Simple Process Manager Interface v1 <spec_13>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The MPI process manager interface (PMI) version 1 is a de-facto
standard API and wire protocol for communication between MPI
runtimes and resource managers. It was added to the MPICH2 MPI-2
reference implementation in late 2001, and has since been widely
implemented, but was not officially standardized by the MPI Forum
and has been only lightly documented. This RFC is an attempt to
document PMI-1 to guide developers of resource managers that must
support current and legacy MPI implementations.

:doc:`14/Canonical Job Specification <spec_14>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A domain specific language based on YAML is defined to express the
resource requirements and other attributes of one or more programs
submitted to a Flux instance for execution. This RFC describes the
canonical form of the jobspec language, which represents a request
to run exactly one program.

:doc:`15/Independent Minister of Privilege for Flux: The Security IMP <spec_15>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes Flux Security IMP, a privileged service
used by multi-user Flux instances to launch, monitor, and control
processes running as users other than the instance owner.

:doc:`16/KVS Job Schema <spec_16>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the format of data stored in the KVS
for Flux jobs.

:doc:`18/KVS Event Log Format <spec_18>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A log format is defined that can be used to log job state
transitions and other date-stamped events.

:doc:`19/Flux Locally Unique ID (FLUID) <spec_19>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes a scheme for a distributed,
uncoordinated *flux locally unique ID* service that generates 64 bit
k-ordered, unique identifiers that are a combination of timestamp
since some epoch, generator id, and sequence number. The scheme is
used to generate Flux job IDs.

:doc:`20/Resource Set Specification <spec_20>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification defines the version 1 format of the resource-set
representation or *R* in short.

:doc:`21/Job States and Events Version 1 <spec_21>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes Flux job states and the events that
trigger job state transitions.

:doc:`22/Idset String Representation <spec_22>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes a compact form for expressing a set of
non-negative, integer ids.

:doc:`23/Flux Standard Duration <spec_23>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes a standard form for time duration.

:doc:`24/Flux Job Standard I/O Version 1 <spec_24>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the format used to represent standard
I/O streams in the Flux KVS.

:doc:`25/Job Specification Version 1 <spec_25>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Version 1 of the domain specific job specification language
canonically defined in RFC14.

:doc:`26/Job Dependency Specification <spec_26>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An extension to the canonical jobspec designed to express the
dependencies between one or more programs submitted to a Flux instance
for execution.

:doc:`27/Flux Resource Allocation Protocol Version 1 <spec_27>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes Version 1 of the Flux Resource Allocation
Protocol implemented by the job manager and a compliant Flux scheduler.

:doc:`28/Flux Resource Acquisition Protocol Version 1 <spec_28>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the Flux service that schedulers use to
acquire exclusive access to resources and monitor their ongoing
availability.

:doc:`29/Hostlist Format <spec_29>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the Flux implementation of the Hostlist Format
-- a compressed representation of lists of hostnames.

:doc:`30/Job Urgency <spec_30>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the Flux job urgency parameter.

:doc:`31/Job Constraints Specification <spec_31>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes an extensible format for the description of
job constraints.

:doc:`32/Flux Job Execution Protocol Version 1 <spec_32>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes Version 1 of the Flux Execution Protocol
implemented by the job manager and job execution system.

:doc:`33/Flux Job Queues <spec_33>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes Flux Job Queues. A Flux Job queue is a named,
user-visible container for job requests sorted by priority.

:doc:`34/Flux Task Map <spec_34>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Flux Task Map is a compact mapping between job task ranks and node IDs.

:doc:`35/Constraint Query Syntax <spec_35>`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Constraint Query Syntax describes a simple text-based syntax for generating
JSON objects in the format described in RFC 31.

.. Each file must appear in a toctree
.. toctree::
   :hidden:

   spec_1
   spec_2
   spec_3
   spec_4
   spec_5
   spec_6
   spec_7
   spec_8
   spec_9
   spec_10
   spec_11
   spec_12
   spec_13
   spec_14
   spec_15
   spec_16
   spec_18
   spec_19
   spec_20
   spec_21
   spec_22
   spec_23
   spec_24
   spec_25
   spec_26
   spec_27
   spec_28
   spec_29
   spec_30
   spec_31
   spec_32
   spec_33
   spec_34
   spec_35
