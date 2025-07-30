.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_22.html

45/Resource Range String Representation
#######################################

This specification describes a compact form for expressing an RFC 14
resource range defined by a min/max/operand/operator combination.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_45.rst
  * - **Editor**
    - Sam Maloney <s.maloney@fz-juelich.de>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Background
**********

:doc:`RFC 14 <spec_14>` allows for resource counts to be given as a range
specified by a min/max/operand/operator combination in a dictionary. A compact
representation of such a range is useful in certain contexts, such as command 
line interfaces.

Implementation
**************

A fully specified range string SHALL have one of two forms:

- *with* a given maximum value: ``min-max:operand:operator``

- *without* a given maximum value: ``min+:operand:operator``

Values for ``min``, ``max``, and ``operand`` in a range string SHALL be
represented in decimal form and SHALL NOT include leading zeroes.

The ``operator`` in a range string SHALL be a single character, without any
quotes, e.g. ``+`` not ``'+'``.

A range using the addition ``'+'`` operator MAY omit it (along with the
preceding colon), e.g. ``1-5:2:+`` MAY be shortened to ``1-5:2``.

A range using the addition ``'+'`` operator and a unit operand MAY omit both
(along with the preceding colons), e.g. ``1-4:1:+`` MAY be shortened to ``1-4``.

A range string MAY be surrounded by square brackets to promote readability,
e.g. ``[1-4:2:*]`` or ``[100+]``.

A range string SHALL consist only of the following characters:

-  The decimal digits: ``0 1 2 3 4 5 6 7 8 9``

-  Hyphen: ``-``

-  Plus sign: ``+``

-  Colon: ``:``

-  Square brackets: ``[ ]``

-  Valid operator characters, currently including:

.. list-table::
   :header-rows: 1

   * - Operator
     - Character
     - Unicode Name
   * - Addition
     - ``+``
     - Plus sign
   * - Multiplication
     - ``*``
     - Asterisk
   * - Exponentiation
     - ``^``
     - Circumflex Accent (ASCII Caret)
