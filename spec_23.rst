.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_23.html

23/Flux Standard Duration
=========================

This specification describes a simple string format used to represent
a duration of time.

-  Name: github.com/flux-framework/rfc/spec_23.rst

-  Editor: Mark A. Grondona <mark.grondona@gmail.com>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Background
----------

Many Flux utilities and services may take a time *duration* as input
either via user-provided options, configuration input, or message payload
contents. To provide a consistent interface, and reduce the chance of
incompatibility between Flux components, it is useful to standardize on
a duration format that is human readable, easily parsed, and compact.

Utilities and services that support the duration form described here are
said to support "Flux Standard Duration."


Implementation
--------------

A Flux Standard Duration SHALL be a string of the form ``N[SUFFIX]``,
where *N* is a floating point number and *SUFFIX* is an OPTIONAL unit.

*N* SHALL have a range of [0:infinity] and SHALL be in a form allowed by
C99  [#f1]_ ``strtof`` or ``strtod``.

The OPTIONAL unit suffix MUST be one of the following (case sensitive):

.. list-table::
   :header-rows: 1

   * - Suffix
     - Name
     - Multiplier
   * - ms
     - milliseconds
     - 1E-3
   * - s
     - seconds
     - 1
   * - m
     - minutes
     - 60
   * - h
     - hours
     - 3600
   * - d
     - days
     - 86400

As a special case, when N is ``infinity`` or ``inf``, the unit suffix SHALL
be omitted.

.. [#f1] `C99 - ISO/IEC 9899:1999 standard <https://www.iso.org/standard/29237.html>`__ section 7.20.1.3: The strtod, strtof, and strtold functions
.. [#f2] `C99 - ISO/IEC 9899:1999 standard <https://www.iso.org/standard/29237.html>`__ section 7.12/4 INFINITY (p: 212-213)
