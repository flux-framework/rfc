.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_38.html

###################################
38/Flux Security Key Value Encoding
###################################

The Flux Security Key Value Encoding is a serialization format
for a series of typed key-value pairs.

- Name: github.com/flux-framework/rfc/spec_38.rst

- Editor: Jim Garlick <garlick@llnl.gov>

- State: raw

********
Language
********

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.

*****************
Related Standards
*****************

- :doc:`15/Independent Minister of Privilege for Flux: The Security IMP <spec_15>`

**********
Background
**********

The flux-security project requires simple objects to be encoded for
communication in the following security-sensitive situations:

- To encode the header component of *J* (signed jobspec plus metadata).

- When communicating options between privileged and unprivileged sections
  of the IMP.

*****
Goals
*****

- Replace JSON for security-sensitive use cases where auditability of
  source code is important.

- Must handle strings and a few scalar types.

- There should be no implicit type conversions.  For example, a value encoded
  as an integer may not be decoded as floating point.

- Design should allow for a simple, embedded C implementation.

**************
Implementation
**************

A single key-value pair SHALL be encoded as the UTF-8 key name, a NULL
character, a type character, a UTF-8 value string, and a NULL character.

Each key SHALL have a length greater than zero.

Keys and string values MAY NOT contain the UTF-8 NULL character.

.. note::
   A zero byte MAY NOT be embedded in any key or value encoding because
   it would be indistinguishable from the NULL field delimiter.  The only UTF-8
   encoding that contains a zero byte is that of the NULL character, therefore
   the NULL character is forbidden.

Value type characters and associated value string encodings are as follows:

s
   String.  The value SHALL be directly represented.
i
   64-bit signed integer.  The value SHALL be formatted by printf(3) using the
   ``PRIi64`` format token.
d
   Double-precision floating point number.  The value SHALL be formatted by
   printf(3) using the ``.6f`` format token.
b
   Boolean.  The value SHALL be either the string "true" or the string "false"
   (lower case).
t
   Timestamp.  The value SHALL be represented as an ISO 8601 timestamp string.

Multiple key-value pairs SHALL be concatenated without additional delimiters,
e.g.  ``key\0Tvalue\0key\0Tvalue\0...key\0Tvalue\0``.

An implementation defined limit SHALL be imposed on the maximum overall size
of a serialized object to avoid resource exhaustion.

************
Test Vectors
************

.. list-table::
   :header-rows: 1

   * - name
     - type
     - value
     - encoding
   * - PATH
     - string
     - /bin:/usr/bin
     - ``PATH\0s/bin:/usr/bin\0``
   * - EMPTY_STRING
     - string
     -
     - ``EMPTY_STRING\0s\0``
   * - JOB_ID_STRING
     - string
     - ƒuzzybunny
     - ``JOB_ID_STRING\0sƒuzzybunny\0``
   * - INT_PLUS
     - integer
     - 42
     - ``INT_PLUS\0i42\0``
   * - INT_MINUS
     - integer
     - -42
     - ``INT_MINUS\0i-42\0``
   * - INT64_MAX
     - integer
     - 9223372036854775807
     - ``INT64_MAX\0i9223372036854775807\0``
   * - INT64_MIN
     - integer
     - -9223372036854775808
     - ``INT64_MIN\0i-9223372036854775808\0``
   * - DOUBLE
     - double
     - 3.0
     - ``DOUBLE\0d3.000000\0``
   * - DOUBLE_INF
     - double
     - INFINITY
     - ``DOUBLE_INF\0dinf\0``
   * - DBL_MIN
     - double
     - 2.2250738585072014e-308
     - ``DBL_MIN\0d0.000000\0``
   * - DBL_MAX
     - double
     - 1.7976931348623158e+308
     - ``DBL_MAX\0d179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368.000000\0``
   * - MINUS_DBL_MAX
     - double
     - -1.7976931348623158e+308
     - ``MINUS_DBL_MAX\0d-179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368.000000\0``
   * - FALSE
     - boolean
     - false
     - ``FALSE\0bfalse\0``
   * - TRUE
     - boolean
     - true
     - ``TRUE\0btrue\0``
   * - TIMESTAMP
     - timestamp
     - 1692370785 (time_t)
     - ``TIMESTAMP\0t2023-08-18T14:59:45Z\0``
