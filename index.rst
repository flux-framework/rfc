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

:doc:`spec_1`
~~~~~~~~~~~~~

The Collective Code Construction Contract (C4.1) is an evolution of
the github.com Fork + Pull Model, aimed at providing an optimal
collaboration model for free software projects.

:doc:`spec_2`
~~~~~~~~~~~~~

The Flux framework is a family of projects used to build
site-customized resource management systems for High Performance
Computing (HPC) data centers. This document specifies licensing and
collaboration guidelines for Flux projects.

:doc:`spec_3`
~~~~~~~~~~~~~

This specification describes the format of Flux messages, Version 1.

:doc:`spec_4`
~~~~~~~~~~~~~

The Flux Resource Model describes the conceptual model used for
resources within the Flux framework.

:doc:`spec_5`
~~~~~~~~~~~~~

This specification describes the broker extension modules used to
implement Flux services.

:doc:`spec_6`
~~~~~~~~~~~~~

This specification describes how Flux Remote Procedure Call (RPC) is
built on top of Flux request and response messages.

:doc:`spec_7`
~~~~~~~~~~~~~

This specification presents the recommended standards when
contributing C code to the Flux code base.

:doc:`spec_9`
~~~~~~~~~~~~~

Establishes best practices, preferred patterns and anti-patterns for
distributed services in the flux framework.

:doc:`spec_10`
~~~~~~~~~~~~~~

This specification describes the Flux content storage service and
the messages used to access it.

:doc:`spec_11`
~~~~~~~~~~~~~~

The Flux Key Value Store (KVS) implements hierarchical key
namespaces layered atop the content storage service described in
RFC 10. Namespaces are organized as hash trees of content-addressed
tree objects and values. This specification defines the version 1
format of key value store tree objects.

:doc:`spec_12`
~~~~~~~~~~~~~~

This document describes the mechanisms used to secure Flux instances
against unauthorized access and prevent privilege escalation and
other attacks, while ensuring programs run with appropriate user
credentials and are contained within their set of allocated
resources.

:doc:`spec_13`
~~~~~~~~~~~~~~

The MPI process manager interface (PMI) version 1 is a de-facto
standard API and wire protocol for communication between MPI
runtimes and resource managers. It was added to the MPICH2 MPI-2
reference implementation in late 2001, and has since been widely
implemented, but was not officially standardized by the MPI Forum
and has been only lightly documented. This RFC is an attempt to
document PMI-1 to guide developers of resource managers that must
support current and legacy MPI implementations.

:doc:`spec_14`
~~~~~~~~~~~~~~

A domain specific language based on YAML is defined to express the
resource requirements and other attributes of one or more programs
submitted to a Flux instance for execution. This RFC describes the
canonical form of the jobspec language, which represents a request
to run exactly one program.

:doc:`spec_15`
~~~~~~~~~~~~~~

This specification describes Flux Security IMP, a privileged service
used by multi-user Flux instances to launch, monitor, and control
processes running as users other than the instance owner.

:doc:`spec_16`
~~~~~~~~~~~~~~

This specification describes the format of data stored in the KVS
for Flux jobs.

:doc:`spec_18`
~~~~~~~~~~~~~~

A log format is defined that can be used to log job state
transitions and other date-stamped events.

:doc:`spec_19`
~~~~~~~~~~~~~~

This specification describes a scheme for a distributed,
uncoordinated *flux locally unique ID* service that generates 64 bit
k-ordered, unique identifiers that are a combination of timestamp
since some epoch, generator id, and sequence number. The scheme is
used to generate Flux job IDs.

:doc:`spec_20`
~~~~~~~~~~~~~~

This specification defines the version 1 format of the resource-set
representation or *R* in short.

:doc:`spec_21`
~~~~~~~~~~~~~~

This specification describes Flux job states and the events that
trigger job state transitions.

:doc:`spec_22`
~~~~~~~~~~~~~~

This specification describes a compact form for expressing a set of
non-negative, integer ids.

:doc:`spec_23`
~~~~~~~~~~~~~~

This specification describes a standard form for time duration.

:doc:`spec_24`
~~~~~~~~~~~~~~

This specification describes the format used to represent standard
I/O streams in the Flux KVS.

:doc:`spec_25`
~~~~~~~~~~~~~~

Version 1 of the domain specific job specification language
canonically defined in RFC14.

:doc:`spec_26`
~~~~~~~~~~~~~~

An extension to the canonical jobspec designed to express the
dependencies between one or more programs submitted to a Flux instance
for execution.

:doc:`spec_27`
~~~~~~~~~~~~~~

This specification describes Version 1 of the Flux Resource Allocation
Protocol implemented by the job manager and a compliant Flux scheduler.

:doc:`spec_28`
~~~~~~~~~~~~~~

This specification describes the Flux service that schedulers use to
acquire exclusive access to resources and monitor their ongoing
availability.

:doc:`spec_29`
~~~~~~~~~~~~~~

This specification describes the Flux implementation of the Hostlist Format
-- a compressed representation of lists of hostnames.

:doc:`spec_30`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This specification describes the Flux job urgency parameter.

:doc:`spec_31`
~~~~~~~~~~~~~~

This specification describes an extensible format for the description of
job constraints.

:doc:`spec_32`
~~~~~~~~~~~~~~

This specification describes Version 1 of the Flux Execution Protocol
implemented by the job manager and job execution system.

:doc:`spec_33`
~~~~~~~~~~~~~~

This specification describes Flux Job Queues. A Flux Job queue is a named,
user-visible container for job requests sorted by priority.

:doc:`spec_34`
~~~~~~~~~~~~~~

The Flux Task Map is a compact mapping between job task ranks and node IDs.

:doc:`spec_35`
~~~~~~~~~~~~~~

The Constraint Query Syntax describes a simple text-based syntax for generating
JSON objects in the format described in RFC 31.

:doc:`spec_36`
~~~~~~~~~~~~~~

This specification defines a method for embedding job submission options
and other directives in files.

:doc:`spec_37`
~~~~~~~~~~~~~~

The File Archive Format defines a JSON representation of a set or list
of file system objects.

:doc:`spec_38`
~~~~~~~~~~~~~~

The Flux Security Key Value Encoding is a serialization format
for a series of typed key-value pairs.

:doc:`spec_39`
~~~~~~~~~~~~~~

The Flux Security Signature is a NUL terminated string that represents
content secured with a digital signature.

:doc:`spec_40`
~~~~~~~~~~~~~~

This specification defines the data format used by the Fluxion scheduler
to store resource graph data in RFC 20 *R* version 1 objects.

:doc:`spec_41`
~~~~~~~~~~~~~~

The Flux Job Information Service provides proxy access to KVS job
information for guest users.

:doc:`spec_42`
~~~~~~~~~~~~~~

The subprocess server protocol is used for execution, monitoring, and
standard I/O management of remote processes.

:doc:`spec_43`
~~~~~~~~~~~~~~

The Flux Job List Service provides read-only summary information for jobs.

:doc:`spec_44`
~~~~~~~~~~~~~~

This specification describes the Flux service that allows users to
receive external notifications for events in a Flux job.

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
   spec_36
   spec_37
   spec_38
   spec_39
   spec_40
   spec_41
   spec_42
   spec_43
   spec_44
