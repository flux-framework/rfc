.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_22.html

22/Idset String Representation
##############################

This specification describes a compact form for
expressing a set of non-negative, integer ids.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_22.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Background
**********

It is often necessary to represent a set of non-negative, integer ids
as a compact string for human input, output, or in messages. For example:

-  A set of task ranks.

-  A set of broker ranks.

-  A set of resource ids or indices.

Implementation
**************

An idset SHALL consist of unique, non-negative integer ids.

Syntax
======

An idset string SHALL consist of elements delimited by commas,
e.g. ``1,2,3,5,6,42``.  Each element SHALL be either a single id or
a range.  Elements MAY appear in any order, and the ids they represent
MAY repeat or overlap, e.g. ``6,4,2,0`` or ``0-3,2``.  The idset
represented by an idset string SHALL be the union of the ids
represented by its elements.

Ids in an idset string SHALL be represented in decimal form.

Ids in an idset string SHALL NOT include leading zeroes.

A range SHALL consist of two ids separated by a hyphen, where the
first id is less than the second, e.g. ``5-8``.  A range SHALL
represent the first id, the second id, and all ids between them.

An idset string MAY be surrounded by square brackets to promote readability,
e.g. ``[1-3,5-6,42]``.

An idset string with no elements SHALL represent the empty idset,
e.g. the empty string or ``[]``.

An idset string SHALL consist only of the following characters:

-  The decimal digits: ``0 1 2 3 4 5 6 7 8 9``

-  Comma: ``,``

-  Hyphen: ``-``

-  Square brackets: ``[ ]``

Normalized and Canonical Forms
==============================

A normalized idset string SHALL represent each id of the idset exactly
once, in ascending numerical order.  If it contains ranges, each maximal
run of two or more consecutive ids SHALL be a single range, and every
other id SHALL be a single id.

A canonical idset string is a normalized idset string that contains
ranges where possible and is not surrounded by square brackets,
e.g. ``1-3,5-6,42``.  Each idset has exactly one canonical idset string.

Encoding
========

An implementation that encodes an idset SHALL produce a normalized idset
string, and SHOULD produce the canonical idset string.

Decoding
========

An implementation MAY limit the largest id it supports.  Such an
implementation SHALL treat a string containing a larger id as if it
were not an idset string.

An implementation that decodes an idset string SHALL accept any idset
string and SHALL reject any string that is not an idset string.

Test Vectors
************

The empty string is shown as *(empty)*.

Each of the following idset strings SHALL be decoded to the idset whose
canonical idset string is shown.  The last column indicates whether the
idset string is normalized.

.. list-table::
   :header-rows: 1

   * - idset string
     - canonical idset string
     - normalized
   * - *(empty)*
     - *(empty)*
     - yes
   * - []
     - *(empty)*
     - yes
   * - 0
     - 0
     - yes
   * - [0]
     - 0
     - yes
   * - 1-2
     - 1-2
     - yes
   * - 1,2
     - 1-2
     - yes
   * - [1-2]
     - 1-2
     - yes
   * - [1,2]
     - 1-2
     - yes
   * - 1-3,5-6,42
     - 1-3,5-6,42
     - yes
   * - 1,2,3,5,6,42
     - 1-3,5-6,42
     - yes
   * - [1-3,5-6,42]
     - 1-3,5-6,42
     - yes
   * - [1,2,3,5,6,42]
     - 1-3,5-6,42
     - yes
   * - 1,2-4
     - 1-4
     - no
   * - 1-3,4
     - 1-4
     - no
   * - 1-2,3-4
     - 1-4
     - no
   * - 6,4,2,0
     - 0,2,4,6
     - no
   * - [3,1]
     - 1,3
     - no
   * - 2,2,2
     - 2
     - no
   * - 0-3,2
     - 0-3
     - no
   * - 5,0-1
     - 0-1,5
     - no

Each of the following strings is not an idset string and SHALL be
rejected.

.. list-table::
   :header-rows: 1

   * - string
     - reason
   * - 01
     - leading zero
   * - -5
     - not a non-negative id
   * - 3-0
     - range endpoints out of order
   * - 2-2
     - range endpoints equal
   * - 1-2-3
     - malformed range
   * - 0-
     - malformed range
   * - 1,,2
     - empty element
   * - 1,
     - empty element
   * - ,
     - empty element
   * - [0
     - unbalanced brackets
   * - [[0]]
     - nested brackets
   * - 1 2
     - invalid character
   * - 4.2
     - invalid character
