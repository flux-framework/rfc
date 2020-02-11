
22/Idset String Representation
==============================

This specification describes a compact form for
expressing a set of non-negative, integer ids.

-  Name: github.com/flux-framework/rfc/spec_22.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Background
----------

It is often necessary to represent a set of non-negative, integer ids
as a compact string for human input, output, or in messages. For example:

-  A set of task ranks.

-  A set of broker ranks.

-  A set of resource ids or indices.


Implementation
--------------

An idset SHALL consist of unique, non-negative integer ids.

An idset string SHALL consist of ids in ascending numerical order,
delimited by commas, e.g. ``1,2,3,5,6,42``.

Ids in an idset string SHALL be represented in decimal form.

Ids in an idset string SHALL NOT include leading zeroes.

Consecutive ids in an idset string MAY be compressed into hyphenated
ranges, e.g. ``1-3,5-6,42``.

An idset string MAY be surrounded by square brackets to promote readability,
e.g. ``[1-3,5-6,42]``.

An idset string SHALL consist only of the following characters:

-  The decimal digits: ``0 1 2 3 4 5 6 7 8 9``

-  Comma: ``,``

-  Hyphen: ``-``

-  Square brackets: ``[ ]``
