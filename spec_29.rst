.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_29.html

29/Hostlist Format
==================

This specification describes a compact form for expressing a list of
hostnames which contain an optional numerical part.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_29.rst
  * - **Editor**
    - Mark A. Grondona <mgrondona@llnl.gov>
  * - **State**
    - raw

Language
--------

.. include:: common/language.rst

Background
----------

The *hostlist* is a somewhat well known format supported by
existing HPC tools such as `pdsh <https://github.com/chaos/pdsh>`_,
`powerman <https://github.com/chaos/powerman>`_, and `genders
<https://github.com/chaos/genders>`_. The format is designed as a convenience
on systems where hostnames are assigned with a common prefix, a numeric
part, and an optional suffix. The result is a compact way to represent
a possibly large list of hosts by name, e.g. ``prefix[0-1024]``.

This RFC details the Flux implementation of the hostlist format.

Implementation
--------------

A *hostlist* SHALL represent an ordered list of strings.

A hostlist string SHALL be a list of comma separated
*hostlist expressions*.

A *hostlist expression* SHALL be a string of the form
``prefix[idlist]suffix``, where all components ``prefix``, ``[idlist]``,
and ``suffix`` are OPTIONAL.

An empty *hostlist expression*, ``""``, SHALL represent an empty list.

The *prefix* and *suffix* components of a *hostlist expression* SHALL
consist of any printable, non-whitespace ASCII character besides the special
characters including square brackets: "``[ ]``", and comma: "``,``".

An *idlist* SHALL represent an ordered list of non-negative integer ids.

An *idlist* MAY be a simple comma-separated list, e.g. ``5,4,10,11,12,13``.

Consecutive ids in an *idlist* MAY be compressed into hyphenated ranges,
e.g. ``5,4,11-13``.

Leading zeros in the first element of an *idlist* SHALL be preserved
across all ids in the list, e.g. ``005,4,11-13`` represents the list
``005,004,011,012,013``.

An *idlist* MAY contain repeated numbers, e.g. ``2,2,2`` is a valid list.

Within a *hostlist expression*, an *idlist* SHALL be enclosed in square
brackets, e.g. ``host[0-10,12]``.

Test Vectors
------------

 - ``""`` = ``""``
 - ``"foox,fooy,fooz"`` = ``"foox,fooy,fooz"``
 - ``"[1-3,5-6]"`` = ``"1,2,3,5,6"``
 - ``"foo[1-5]"`` = ``"foo1,foo2,foo3,foo4,foo5"``
 - ``"foo[0-4]-eth2"`` = ``"foo0-eth2,foo1-eth2,foo2-eth2,foo3-eth2,foo4-eth2"``
 - ``"foo1,foo1,foo1"`` = ``"foo1,foo1,foo1"``
 - ``"[00-02]"`` = ``"00,01,02"``
 - ``"[00-2]"`` = ``"00,01,02"``
 - ``"foo[1,1,2,1]"`` = ``"foo1,foo1,foo2,foo1"``
