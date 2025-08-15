.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_46.html

46/Command Line Job Specification Resources Shape
#################################################

This specification describes a compact form for expressing an RFC 14 jobspec
resources list that can be provided to several Flux commands by a user.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_46.rst
  * - **Editor**
    - Sam Maloney <s.maloney@fz-juelich.de>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

-  :doc:`spec_4`
-  :doc:`spec_14`
-  :doc:`spec_22`
-  :doc:`spec_25`
-  :doc:`spec_45`


Goals
*****

- Express a resource specification on the command line (a.k.a. a "shape") to
  expand into the resources list of a Canonical Job Specification.

- The shape should make simple resource requests compact and easy to express,
  but without restricting complex requests from being fully specifiable.

- Allow inclusion in several submission contexts, including submit, run, and batch.


Overview
********

This RFC describes a "shape" string that can be expanded into the full YAML
or JSON representation of the equivalent :doc:`RFC 14 <spec_14>` Job
Specification resources list.

Description
***********

A shape string is essentially a compacted form of the equivalent JSON array,
according to the following rules:

- Every level of the resource graph (including the outermost level) is a list
  of resource vertices which SHALL be separated by a semicolon ``;`` (to reduce
  ambiguity with commas in idsets for counts) and the entire list SHALL in
  general be surrounded by square brackets ``[...]`` except:

  - If a list contains only a single vertex then the brackets MAY be omitted.

- A resource vertex is a dictionary which SHALL be represented by the general
  form ``<type>=<count>{<key>:<value>}``, where ``<type>`` and ``<count>`` are
  the *values* of the corresponding mandatory keys, and the following apply:

  - Strings such as ``<type>``, ``<key>``, or a string type ``<value>`` do not
    need to be quoted unless they contain special characters (or would otherwise
    be parsed as a different ``<value>`` type).

  - ``<count>`` SHALL be one of a positive integer, an :doc:`RFC 22 <spec_22>`
    idset, or an :doc:`RFC 45 <spec_45>` compact range string (i.e. not a range
    dictionary).

  - If the ``<count>`` is integer ``1`` then it (and the ``=``) MAY be omitted.

  - If the ``<type>`` is ``slot`` then the first entry in the braces SHALL be
    the *value* (and only the value) of the mandatory ``label`` key, except:

    - If there is only a single ``slot`` vertex in the entire jobspec, then the
      label MAY be omitted; however, if there are any other ``<key>:<value>``
      pairs then the label is REQUIRED and MUST be the first entry.

  - Additional ``<key>:<value>`` pairs SHALL be separated by a comma ``,``.

  - Boolean keys (e.g. ``exclusive``) MAY omit the ``:<value>`` and instead:

    - Prepend either ``+`` or ``-`` to the key name to indicate ``true`` or
      ``false`` respectively, or:

    - Add nothing to indicate an implicit value of ``true``.

  - As a special case, the ``exclusive`` key may be shortened to simply ``x``.

  - The ``<value>`` should be a `valid JSON value
    <https://datatracker.ietf.org/doc/html/rfc8259#section-3>`_, except:

    - Objects (sub-dictionaries) MAY be specified with the same syntax as the
      outer dict (i.e. using unquoted strings/keys and shortened booleans).

  - If there are no ``<key>:<value>`` pairs or slot ``<label>`` then the empty
    braces SHOULD be omitted.

- The ``with`` key SHALL be represented by a forward slash ``/`` as the final
  character of a resource vertex, immediately followed by its child resource
  level according to the definitions above.

Grammar
*******

The basic grammar for the command line jobspec resources language is

.. code-block:: PEG

   resources   : list

   list        : '[' vertex (';' vertex)* ']'
               | vertex

   vertex      : 'slot' ('=' count)? ('{' label (',' item)* '}')? '/' list
               | type ('=' count)? dict? ('/' list)?

   type        : STRING

   label       : STRING

   count       : '[' count-value ']'
               | count-value

   count-value : RANGE
               | IDSET
               | INTEGER

   dict        : '{' (item (',' item)*)? '}'

   item        : key ':' VALUE
               | (+|-)? key

   key         : 'x'
               | STRING

Examples
********

In this section we will demonstrate how the resource lists from the jobspec for
each of the Basic Use Cases in :doc:`RFC 14 <spec_14>` can be represented as a
command line shape string.

Section 1: Node-level Requests
==============================

Use Case 1.1
   ``slot=4/node``

   .. code-block:: yaml

      - type: slot
        count: 4
        label: default
        with:
        - type: node
          count: 1

Use Case 1.2
   ``slot=3-30/node``

   .. code-block:: yaml

      - type: slot
        count:
          min: 3
          max: 30
          operator: +
          operand: 1
        label: default
        with:
        - type: node
          count: 1

Use Case 1.3
   ``slot=4{nodelevel}/node{-x}/socket=2+/core=4+``

   N.B. in this case (and 1.4) there is only one ``slot`` so the label is
   optional, but may always be included to define a specific name.
 
   .. code-block:: yaml

      - type: slot
        count: 4
        label: nodelevel
        with:
        - type: node
          count: 1
          exclusive: false
          with:
          - type: socket
            count:
              min: 2
            with:
            - type: core
              count:
                min: 4

Use Case 1.4
   ``slot=4{nodelevel}/node/socket=2/core=4``
 
   .. code-block:: yaml

      - type: slot
        count: 4
        label: nodelevel
        with:
        - type: node
          count: 1
          with:
          - type: socket
            count: 2
            with:
            - type: core
              count: 4

Use Case 1.5
   ``[cluster/slot=2{ib}/node/[memory=4{unit:GB};ib10g];switch/slot=2{bicore}/node/core=2]``
 
   .. code-block:: yaml

      - type: cluster
        count: 1
        with:
        - type: slot
          count: 2
          label: ib
          with:
          - type: node
            count: 1
            with:
            - type: memory
              count: 4
              unit: GB
            - type: ib10g
              count: 1
      - type: switch
        count: 1
        with:
        - type: slot
          count: 2
          label: bicore
          with:
          - type: node
            count: 1
            with:
            - type: core
              count: 2

Use Case 1.6
   ``cluster=2/slot/node=1+{-x}/core=30``
 
   .. code-block:: yaml

      - type: cluster
        count: 2
        with:
        - type: slot
          count: 1
          label: default
          with:
          - type: node
            count:
              min: 1
            exclusive: false
            with:
            - type: core
              count: 30

Use Case 1.7
   ``switch=3/slot/node=1+{-x}/core``
 
   .. code-block:: yaml

      - type: switch
        count: 3
        with:
        - type: slot
          count: 1
          label: default
          with:
          - type: node
            count:
              min: 1
            exclusive: false
            with:
            - type: core
              count: 1

Use Case 1.8
   ``slot=4,9,16,25/node``
 
   .. code-block:: yaml

      - type: slot
        count: 4,9,16,25
        label: default
        with:
        - type: node
          count: 1

Section 2: General Requests
===========================

Use Case 2.1 and 2.2
   Resource list is the same as 1.1

Use Case 2.3
   ``slot=10/core=2``
  
   .. code-block:: yaml

      - type: slot
        count: 10
        label: default
        with:
        - type: core
          count: 2

Use Case 2.4
   ``node/[slot=10{read-db}/[core;memory=4{unit:GB}];slot{db}/[core=6;memory=24{unit:GB}]]``

   .. code-block:: yaml

      - type: node
        count: 1
        with:
        - type: slot
          count: 10
          label: read-db
          with:
          - type: core
            count: 1
          - type: memory
            count: 4
            unit: GB
        - type: slot
          count: 1
          label: db
          with:
          - type: core
            count: 6
          - type: memory
            count: 24
            unit: GB

Use Case 2.5
   ``slot=10/[memory=2+{unit:GB};core]``

   .. code-block:: yaml

      - type: slot
        count: 10
        label: default
        with:
        - type: memory
          count:
            min: 2
          unit: GB
        - type: core
          count: 1

Use Case 2.6
   ``slot=2{4GB-node}/node/memory=4+{unit:GB}``

   .. code-block:: yaml

      - type: slot
        count: 2
        label: 4GB-node
        with:
        - type: node
          count: 1
          with:
          - type: memory
            count:
              min: 4
            unit: GB

Use Case 2.7, 2.8, and 2.9
   ``slot/node``

   .. code-block:: yaml

      - type: slot
        count: 1
        label: default
        with:
        - type: node
          count: 1
