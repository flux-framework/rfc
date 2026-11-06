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

An idset string SHALL consist of elements delimited by commas,
e.g. ``1,2,3,5,6,42``.  Each element SHALL be either a single id or
a range.  The ids represented by the elements SHALL be in ascending
numerical order.

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
