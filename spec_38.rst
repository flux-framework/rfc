.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_37.html

38/Command Line Job Specification Version 1
===========================================

The Command Line Job Specification includes specification of a shape string
that can be provided to several Flux commands by a user to expand into a resource
graph. This RFC describes version 1 of jobspec, which represents a request 
to run one or more tasks, and can be provided to a flux run, batch, or submit.

-  Name: github.com/flux-framework/rfc/spec_37.rst
-  Editor: Vanessa Sochat <sochat1@llnl.gov>
-  State: raw

Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`4/Flux Resource Model <spec_4>`

-  :doc:`8/Flux Task and Program Execution Services <spec_8>`

-  :doc:`14/Canonical Job Specification <spec_14>`

-  :doc:`20/Resource Set Specification Version 1 <spec_20>`

-  :doc:`25/Job Specification Version 1 <spec_25>`

-  :doc:`26/Job Dependency Specification <spec_26>`

-  :doc:`31/Job Constraints Specification <spec_31>`


Goals
-----

-  Express a resource specification on the command line, a "shape." to expand into the resources of a Job Specification (rfc 25).

-  The shape should include resources, counts, attributes, and grouping.

-  Allow to be included in several submission contexts, including submit, run, and batch.


Overview
--------

This RFC describes the version 1 form of the command line jobspec,
a string that can be expanded out into a Job Specification resources section.
The version 1 of the command line jobspec SHALL consist of
a single string of resources, attributes, and groups that can be mapped out
into a YAML document representing a reusable request to run
one or more tasks on a set of resources. 


Command Line Job Definition
---------------------------

A command line V1 specification SHALL consist of a shape definition,
a string that describes resources, attributes, and groups. This
shape specification can be expanded to the ``resources`` section
of a YAML document. The shape SHALL meet the form and requirements
listed in detail in the sections below. 


Shape
~~~~~

The value of the ``shape`` key SHALL be a single shape (string value).
A shape is expanded into a resource definition. Only one of shape OR
resources is allowed, and one is required. A shape takes the general format
of ``Resource[Count+Attribute]`` where:

- ``Resource`` includes the set defined below
- ``Count`` is a positive integer to indicate the number of the resource
- ``Attribute`` is indicated by the presence of a ``+`` and can be a key value pair ``+label=nodes`` or a boolean value ``+exclusive``

And groups of resources can be indicated by adding parentheses, and having
resources inside the group separated by a comma. E.g.,: ``A(B[1],C[2])``.

Each of these will be described in further detail.

Resource
^^^^^^^^

A resource is a named entity that represents a physical or virtual resource.
The name of the resource MAY be lowercase, but it SHOULD be capitalized.
Resource groups are separated by colons ``:``.
As an example, the following shape indicates a single node with 1 core:

.. ::code-block console

    Node:Core

and is expanded to

.. ::code-block yaml

    resources:
    - type: Node
      count: 1
      with:
        - type: Core
          count: 1

In the YAML above, note that the resource name (e.g., "Node" or "Core") is mapped
to the resources "type," and is always added as an item in a list. Given that a resource
list has children, these are appended via the "with" attribute. 


Count
^^^^^

Note that for a count of 1 for any resource, it MAY be defined but is optional.
All of these shapes would expand to the same resources shown above:

.. ::code-block console

    Node:Core
    Node:Core[1]
    Node[1]:Core
    Node[1]:Core[1]


The ``count`` is thus optional, and when provided, must be a positive integer value.
The count maps directly to the number we provided in brackets, and when not present, it defaults to 
1.

Attributes
^^^^^^^^^^

Attributes are additional qualifiers that can be added to any resource, inside
of the brackets. An attribute MUST be a known resource vertex as defined in RFC
25. Attributes can be key value pairs or a boolean, where each is prefixed by a
``+``. For a key value pair, the format is ``[+key=value]`` and for a boolean
flag (to indicate presence) it takes the general format ``[+flag]``.
As an example, starting with these shapes (that are equivalent):


.. ::code-block console

    Node[4]:Slot:Core[2]
    Node[4]:Slot[1]:Core[2]

Are equivalent and are expanded to:

.. ::code-block yaml

    resources:
      - type: node
        count: 4
        with:
          - type: slot
            count: 1
            with:
              - type: core
                count: 2


To add the attribute "label" to the same graph we might do:

.. ::code-block console

    Node[4]:Slot[+label=default]:Core[2]
    Node[4]:Slot[1+label=default]:Core[2]


To generate this YAML document:

.. ::code-block yaml

    resources:
      - type: node
        count: 4
        with:
          - type: slot
            count: 1
            label: default
            with:
              - type: core
                count: 2


Note that when a number is provided, it doesn't need an additional separator
between the count (1) and label as the ``+`` acts as this delimiter.

Groups
^^^^^^

Finally, it is possible to define multiple resources at the same level with the addition
of parentheses. We call this a group. As an example, this shape:

.. ::code-block console

    Node[5]:(Core[5],GPU[1])

Would map to this resource graph:

.. ::code-block yaml

    resources:
      - type: node
        count: 5
        with:
          - type: core
            count: 5
          - type: gpu
            count: 1

The assumption of this design is that most shape specifications would not have
huge complexity of nesting. Any resource specification that warrants such complexity
would best be defined in a YAML document directly.
