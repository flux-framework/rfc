.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_20.html

20/Resource Set Specification Version 1
=======================================

This specification defines the version 1 format of the resource-set
representation or *R* in short.

-  Name: github.com/flux-framework/rfc/spec_20.rst

-  Editor: Dong H. Ahn <ahn1@llnl.gov>

-  State: Raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL"
in this document are to be interpreted as described in RFC 2119.


Related Standards
-----------------

-  :doc:`4/Flux Resource Model <spec_4>`

-  :doc:`14/Canonical Job Specification <spec_14>`

-  :doc:`15/Independent Minister of Privilege for Flux <spec_15>`

-  :doc:`16/KVS Job Schema <spec_16>`

-  :doc:`22/Idset String Representation <spec_22>`

-  :doc:`29/Hostlist Format <spec_29>`


Overview
--------

Flexible resource representation is important for some of the key
components of Flux.
Resource requests are part of Flux jobspec, described in RFC 14.
This RFC describes the format of a concrete resource-set representation
referred to as *R*, constructed by the scheduler in response
to a resource request.
*R* is input to the remote execution system, which uses information
expressed in *R* to establish containment, binding, mapping,
and execution of program tasks, apportioned across broker ranks.
As a program terminates, the execution system releases
shards of the original *R*, eventually
adding up to its union, back to the scheduler.
Finally, when a Flux instance launches a child instance,
*R* is passed down from the enclosing instance to the child instance,
where it primes the child scheduler with a block of allocatable resources.


Design Goals
------------

The *R* format is designed with the following goals:

-  Allow the resource data conformant to our resource model (RFC 4)
   to be serialized and deserialized with no data loss;

-  Express the resource allocation information to the execution service;

-  Use the same format to release a resource subset of *R* to the scheduler;

-  Allow the consumers of *R* to deserialize an *R* object while minimizing
   the parsing complexity and the data to read;


Producers and Consumers
-----------------------

-  The scheduler for a Flux instance (or instance scheduler) uses
   this format to serialize each resource allocation
   as REQUIRED by the instance program execution service and OPTIONALLY
   REQUIRED by child scheduler instances.

-  The instance scheduler deserializes an *R* object to build
   its internal resource data used for scheduling.

-  Users MAY manually write an *R* object for testing and debugging.

-  User-facing utilities that query a resource status (e.g., what
   resources are available or idle, or what resources are allocated to a job)
   MAY use an *R* object to extract this information;

-  The program execution service emits a valid *R* object to release
   a resource subset of an *R* to the instance scheduler.


Resource Set Format Definition
------------------------------

The JSON documents that conform to the *R* format SHALL be referred
to as *R* JSON documents or in short *R* documents.
An *R* JSON document SHALL consist of a dictionary with four
keys: ``version``, ``execution``, ``scheduling`` and ``attributes``.
It SHALL be valid if and only
if it contains the ``version`` key and either or both the ``execution``
and ``scheduling`` keys. The value of the ``execution`` key SHALL contain
sufficient data for the execution system to perform its
core tasks. The value of ``scheduling`` SHALL contain sufficient data
for schedulers. Finally, the value of ``attributes`` SHALL provide
optional information including but not being limited
to data specific to the scheduler used to create
this JSON document.


Version
~~~~~~~

The value of the ``version`` key SHALL contain 1 to indicate
the format version.


Execution
~~~~~~~~~

The value of the ``execution`` key SHALL contain at least the keys
``R_lite``, and ``nodelist``, with optional keys ``properties``,
``starttime`` and ``expiration``. Other keys are reserved for future
extensions.

``R_lite`` is a strict list of dictionaries each of which SHALL contain
at least the following two keys:

**rank**
   The value of the ``rank`` key SHALL be a string list of
   broker rank identifiers in **idset format** (See RFC 22). This list
   SHALL indicate the broker ranks to which other information in
   the current entry applies.

**children**
   The ``children`` key encodes the information about certain compute resources
   contained within this compute node. The value of this key SHALL contain a dictionary
   with two keys: ``core`` and ``gpu``. Other keys are reserved for future
   extensions.

   **core**
      The ``core`` key SHALL contain a logical compute core IDs string
      in RFC 22 **idset format**.

   **gpu**
      The OPTIONAL ``gpu`` key SHALL contain a logical GPU IDs string
      in RFC 22 **idset format**.


The ``nodelist`` key SHALL be an array of hostnames which correspond to
the ``rank`` entries of the ``R_lite`` dictionary, and serves as a mapping
of ``R_lite`` ``rank`` entries to hostname. Each entry in ``nodelist`` MAY
contain a string in RFC 29 *Hostlist Format*, e.g. ``host[0-16]``.

The ``execution`` key MAY also contain any of the following optional keys:

**properties**
   The optional properties key SHALL be a dictionary where each key maps a
   single property name to a RFC 22 idset string. The idset string SHALL
   represent a set of execution target ranks. A given execution target
   rank MAY appear in multiple property mappings. Property names SHALL
   be valid UTF-8, and MUST NOT contain the following illegal characters:

   ::

      ! & ' " ^ ` | ( )

   Additionally, the ``@`` character is reserved for scheduler specific
   property use. In this case, the literal property SHALL still apply
   to the defined execution target ranks, but the scheduler MAY use the
   suffix after ``@`` to apply the property to children resources of the
   execution target or for another scheduler specific purpose. For example,
   the property ``amd-mi50@gpu`` SHALL apply to the defined execution
   target ranks, but a scheduler MAY use the ``gpu`` suffix to perform
   scheduling optimization for gpus of the corresponding ranks. This MAY
   result in both ``amd-mi50@gpu`` and ``amd-mi50`` being valid properties
   for resources in the instance.

**starttime**
   The value of the ``starttime`` key, if present, SHALL
   encode the start time at which the resource set is valid. The
   value SHALL be the number of seconds elapsed since the Unix Epoch
   (1970-01-01 00:00:00 UTC) with optional microsecond precision.
   If ``starttime`` is unset, then the resource set has no specified
   start time and is valid beginning at any time up to ``expiration``.

**expiration**
   The value of the ``expiration`` key, if present, SHALL
   encode the end or expiration time of the resource set in seconds
   since the Unix Epoch, with optional microsecond precision. If
   ``starttime`` is also set, ``expiration`` MUST be greater than
   ``starttime``. If ``expiration`` is unset, the resource set has no
   specified end time and is valid beginning at ``starttime`` without
   expiration.


Scheduling
~~~~~~~~~~

The ``scheduling`` key MAY contain scheduler-specific resource data.  It
SHALL NOT be interpreted other Flux components.  When used, it SHALL ride
along on the resource acquisition protocol (RFC 28) and resource allocation
protocol (RFC 27) so that it may be included in static configuration,
allocated to jobs, and passed down a Flux instance hierarchy.


Attributes
~~~~~~~~~~
The purpose of the ``attributes`` key is to provide optional
information on this *R* document. The ``attributes`` key SHALL
be a dictionary of one key: ``system``.
Other keys are reserved for future extensions.

**system**
Attributes in the ``system`` dictionary provide additional system
information that have affected the creation of this *R* document.
All of the system attributes are optional.

A common system attribute is:

**scheduler**
The value of the ``scheduler`` is a free-from dictionary that
may provide the information specific to the scheduler used
to produce this document. For example, a scheduler that
manages multiple job queues may add ``queue=batch``
to indicate that this resource set was allocated from within
its ``batch`` queue.


Example R
~~~~~~~~~

The following is an example of a version 1 resource specification.
The example below indicates a resource set with the ranks 19
through 22.  These ranks correspond to the nodes node186 through
node189.  Each of the nodes contains 48 cores (0-47) and 8 gpus (0-7).
The ``startime`` and ``expiration`` indicate the resources were valid
for about 30 minutes on February 16, 2023.

.. literalinclude:: data/spec_20/example1.json
   :language: json

