
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
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


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

A duration in Flux Standard Duration SHALL be of the form ``N[SUFFIX]`` where
``SUFFIX`` SHALL be optional and, if provided, MUST be a single character from the
set ``s,m,h,d``. The value ``N`` MUST be a non-negative, non-infinite,
floating-point number excluding ``NaN``. The value ``N`` SHALL be in one of the
forms allowed by C99  [#f1]_ ``strtof`` or ``strtod`` and SHALL be interpreted as:

-  *seconds* if ``SUFFIX`` is not provided, or is ``s``.

-  *minutes* if ``SUFFIX`` is ``m``.

-  *hours* if ``SUFFIX`` is ``h``.

-  *days* if ``SUFFIX`` is ``d``.

.. [#f1] `C99 - ISO/IEC 9899:1999 standard <https://www.iso.org/standard/29237.html>`__ section 7.20.1.3: The strtod, strtof, and strtold functions
