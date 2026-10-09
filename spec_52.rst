.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_52.html

:smartquotes: false

52/D-Bus Bridge Protocol
########################

This specification defines a JSON encoding of D-Bus message bodies and the
Flux RPC protocol used to make D-Bus method calls and receive D-Bus signals
through the Flux ``sdbus`` service.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_52.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_6`

Background
**********

D-Bus is a message bus used by systemd and other system services.  Each
D-Bus message carries a body consisting of zero or more values whose types
are described by a *type signature* [#f1]_.

The Flux ``sdbus`` service translates Flux RPCs to D-Bus method calls and
D-Bus method replies and signals to Flux responses.  Message bodies are
carried in Flux payloads using the JSON encoding defined here.

JSON [#f2]_ has fewer types than D-Bus, so the encoding of a value alone
cannot determine its D-Bus type.  This encoding pairs each body with its
signature, so that every encoded body can be converted back to an
equivalent D-Bus body.  Dict entry order and file descriptor numbers are
not preserved.

Goals
*****

- Represent any D-Bus message body in JSON.

- Translate in both directions without loss, given the signature.

- Require no per-method translation code.

- Remain within the interoperable subset of JSON.

Terminology
***********

The terms *basic type*, *container type*, *single complete type*, and
*signature* are used as defined in the D-Bus Specification [#f1]_.

In this specification, *encoding* translates a D-Bus value to JSON and
*decoding* translates JSON to a D-Bus value.  Thus the service decodes
the body of a request and encodes the body of a method return or
signal.

Value Encoding
**************

A D-Bus value SHALL be encoded as a JSON value according to its single
complete type, as follows.

.. list-table::
  :header-rows: 1
  :widths: 15 15 70

  * - Code
    - D-Bus Type
    - JSON Encoding
  * - ``y``
    - BYTE
    - integer
  * - ``b``
    - BOOLEAN
    - ``true`` or ``false``
  * - ``n``
    - INT16
    - integer
  * - ``q``
    - UINT16
    - integer
  * - ``i``
    - INT32
    - integer
  * - ``u``
    - UINT32
    - integer
  * - ``x``
    - INT64
    - string (see `64-bit Integers`_)
  * - ``t``
    - UINT64
    - string (see `64-bit Integers`_)
  * - ``d``
    - DOUBLE
    - number
  * - ``s``
    - STRING
    - string
  * - ``o``
    - OBJECT_PATH
    - string
  * - ``g``
    - SIGNATURE
    - string
  * - ``h``
    - UNIX_FD
    - object, requests only (see `File Descriptors`_)
  * - ``a``\ *T*
    - ARRAY
    - array, one element per D-Bus element, in order
  * - ``a{``\ *KV*\ ``}``
    - ARRAY of DICT_ENTRY
    - object or array (see `Dictionaries`_)
  * - ``(``\ *...*\ ``)``
    - STRUCT
    - array, one element per member, in order
  * - ``v``
    - VARIANT
    - array (see `Variants`_)

Integers
========

An integer value SHALL be within the range of its D-Bus type.

64-bit Integers
===============

JSON implementations are not required to represent integers outside the
range :math:`[-(2^{53})+1, 2^{53}-1]` exactly [#f2]_.

``x`` and ``t`` values SHALL be encoded as JSON strings containing the
value in decimal, with no leading zeros, no leading ``+``, and no
whitespace.  A negative ``x`` value SHALL have a leading ``-``.  A decoder
SHALL reject any other representation.

Example: the ``t`` value 18446744073709551615 is encoded as
``"18446744073709551615"``.

Doubles
=======

A decoder SHALL accept any JSON number for ``d``, with or without a
fraction or exponent part.  NaN and infinite values cannot be represented
and SHALL cause encoding to fail.

Strings
=======

``s``, ``o``, and ``g`` values SHALL be encoded as JSON strings with the
same content as the D-Bus value.  Object paths SHALL be carried verbatim.
A decoder SHALL reject strings that are not valid for the D-Bus
type, including strings containing U+0000.

File Descriptors
================

An ``h`` value SHALL be a JSON object with the following members:

fd
  (integer, REQUIRED) The file descriptor number.  It SHALL be
  non-negative.

pid
  (integer, REQUIRED) The process id of the requesting process, per
  getpid(2).  It SHALL be positive.

Encoding an ``h`` value SHALL fail, so ``h`` values occur only in
requests.  A method return containing one cannot be translated, and a
signal containing one may be dropped (see `Method Call`_ and
`Signal Subscription`_).  This is a deliberate restriction: D-Bus
delivers the descriptor into the service's process, so the service
could duplicate it and encode it with its own process id, but it
cannot determine whether the receiver shares its process.  A duplicate
sent outside the owning process would be rejected by the receiver's
``pid`` check and leaked in the service.

The descriptor number is valid only within the process that owns it.
A requester SHALL NOT send an ``h`` value unless it executes in the same
process as the ``sdbus`` service.  A decoder SHALL fail unless ``pid``
equals its own process id.  This check guards against accidental use of
a descriptor number outside the owning process; it is not a security
mechanism.

An ``h`` value does not transfer ownership of the descriptor.  The
requester SHALL keep the descriptor open until it receives a response,
since translation does not necessarily occur immediately.  Translation
MAY substitute a duplicate descriptor, so the number is not preserved.

Dictionaries
============

An array of dict entries with a key of type ``s``, ``o``, or ``g`` SHALL be
encoded as a JSON object with one member per entry.  The member name is the
key; the member value is the encoded value.  D-Bus dict entry order is not
preserved.  A D-Bus dict containing duplicate keys SHALL cause encoding to
fail.  A decoder is not required to detect duplicate member names in a
JSON object, since JSON parsers commonly discard all but one.

An array of dict entries with a key of any other basic type SHALL be encoded
as a JSON array with one element per entry, in order.  Each element SHALL be
a two-element JSON array containing the encoded key and the encoded value.

Variants
========

A variant SHALL be encoded as a two-element JSON array:

.. code:: text

   [SIGNATURE, VALUE]

where SIGNATURE is a string containing a single complete type and VALUE is
the contained value, encoded according to SIGNATURE.

Message Body Encoding
*********************

A D-Bus message body SHALL be encoded as a signature and a parameter array:

signature
  (string) The body signature.  It MAY be empty.

params
  (array) One element per single complete type in ``signature``, in order,
  each encoded according to its type.

The number of elements in ``params`` SHALL equal the number of single
complete types in ``signature``.

A signature SHALL conform to the D-Bus Specification, including the
limits on length and container nesting depth.

sdbus Service
*************

The ``sdbus`` service MAY be registered under an implementation-defined
service name, for example ``sdbus`` for the user bus and ``sdbus-sys`` for
the system bus.  ``SERVICE`` below denotes that name.

Requests SHALL be rejected unless authorized by the instance owner.

Method Call
===========

A D-Bus method call is requested with ``SERVICE.call``.  The request payload
is a JSON object with the following keys:

destination
  (string, REQUIRED) Bus name of the destination.

path
  (string, REQUIRED) Object path.

interface
  (string, REQUIRED) Interface name.

member
  (string, REQUIRED) Method name.

signature
  (string, REQUIRED) Signature of the method call body.

params
  (array, REQUIRED) The method call body, encoded as described in
  `Message Body Encoding`_.

On D-Bus method return, the service SHALL respond with a JSON object
containing the following keys:

signature
  (string, REQUIRED) Signature of the method return body.

params
  (array, REQUIRED) The method return body.

A request that cannot be translated SHALL fail with errnum EPROTO.
A method return that cannot be translated SHALL cause the request to
fail with errnum EPROTO.

Method Errors
=============

On D-Bus method error, the service SHALL respond with an RFC 6 error
response.

errnum SHALL be the POSIX errno value mapped from the D-Bus error name,
or EINVAL if there is no mapping.  Mappings for well-known error names
are listed in sd-bus-errors(3) [#f5]_.

The error string SHALL be the D-Bus error name.  If the error has a
message, the name SHALL be followed by ``:``, a space, and the message.
The error message is the first body element if the body signature begins
with ``s``.  Other body elements SHALL NOT be included.

Since D-Bus error names cannot contain ``:``, the name MAY be recovered by
splitting the error string at the first ``:``.

Signal Subscription
===================

D-Bus signals are received with the streaming RPC ``SERVICE.subscribe``.
The request payload is a JSON object with the following keys:

path
  (string, OPTIONAL) Object path glob, matched with fnmatch(3)
  and ``FNM_PATHNAME``.

interface
  (string, OPTIONAL) Interface name, matched exactly.

member
  (string, OPTIONAL) Signal name, matched exactly.

An absent key matches any value.  Signals are matched without regard to
the sending bus connection.  Each matching signal SHALL be sent as a
response containing the following keys, except that a signal whose body
cannot be translated MAY be dropped:

path
  (string, REQUIRED) Object path of the signal.

interface
  (string, REQUIRED) Interface of the signal.

member
  (string, REQUIRED) Name of the signal.

signature
  (string, REQUIRED) Signature of the signal body.

params
  (array, REQUIRED) The signal body.

The subscription SHALL be canceled as described in RFC 6, using
``SERVICE.subscribe-cancel``.

Related Formats
***************

The encoding is structurally compatible with the JSON output of
busctl(1) (``--json``, systemd 240), also available as
sd_bus_message_dump_json(3) (systemd 258) [#f3]_ [#f4]_.
It differs as follows:

- The body is carried as ``signature`` and ``params`` rather than
  ``type`` and ``data``.

- A variant is ``[SIGNATURE, VALUE]`` rather than
  ``{"type": SIGNATURE, "data": VALUE}``.

- ``x`` and ``t`` are strings.

- A dict with a non-string key type is an array of ``[KEY, VALUE]`` pairs
  rather than an object with keys converted to strings.

- Encoding ``h`` fails rather than producing an object describing the
  file.  In requests, ``h`` is an object containing the descriptor
  number and owning process id.

Examples
********

Start a transient unit
(``org.freedesktop.systemd1.Manager.StartTransientUnit``):

.. code:: json

   {
     "destination": "org.freedesktop.systemd1",
     "path": "/org/freedesktop/systemd1",
     "interface": "org.freedesktop.systemd1.Manager",
     "member": "StartTransientUnit",
     "signature": "ssa(sv)a(sa(sv))",
     "params": [
       "shell-1234.service",
       "fail",
       [
         ["Description", ["s", "sleep for a bit"]],
         ["ExecStart", ["a(sasb)", [["/bin/sleep", ["sleep", "60"], false]]]],
         ["MemoryMax", ["t", "18446744073709551615"]],
         ["StandardOutputFileDescriptor", ["h", {"fd": 5, "pid": 2345}]]
       ],
       []
     ]
   }

The ``h`` value in this example is permitted only because the requester
runs in the same process as the ``sdbus`` service (see
`File Descriptors`_).

Method return:

.. code:: json

   {
     "signature": "o",
     "params": ["/org/freedesktop/systemd1/job/42"]
   }

Method error (RFC 6 error string, errnum ENOENT):

.. code:: text

   org.freedesktop.systemd1.NoSuchUnit: Unit shell-1234.service not loaded.

``PropertiesChanged`` signal on a service unit:

.. code:: json

   {
     "path": "/org/freedesktop/systemd1/unit/shell_2d1234_2eservice",
     "interface": "org.freedesktop.DBus.Properties",
     "member": "PropertiesChanged",
     "signature": "sa{sv}as",
     "params": [
       "org.freedesktop.systemd1.Service",
       {
         "MainPID": ["u", 4242],
         "ExecMainStartTimestamp": ["t", "1759771234567890"],
         "ExecStart": [
           "a(sasbttttuii)",
           [
             [
               "/bin/sleep", ["sleep", "60"], false,
               "1759771234567890", "81234567", "0", "0",
               4242, 0, 0
             ]
           ]
         ]
       },
       []
     ]
   }

Test Vectors
************

.. spelling:word-list::

   aas
   ai
   bb
   dev
   eservice
   eth
   ExecStart
   fd
   freedesktop
   getpid
   mtu
   nan
   nn
   pid
   qq
   sa
   ss
   si
   sasb
   sasbttttuii
   ssa
   sv
   svs
   tt
   uu
   uv
   yy

D-Bus message bodies are written in the parameter notation of busctl(1)
[#f3]_: the signature, followed by the values.  An array is written as its
element count followed by its elements, a variant as its signature followed
by its value, and a struct or dict entry as its members.  Strings are
unquoted, except the empty string ``""``.

JSON values are compared as values, not text.  In particular, object member
order is not significant.

``h`` values do not appear in valid bodies, since encoding fails and
the ``pid`` member depends on the requesting process.

Valid Bodies
============

Encoding the D-Bus body SHALL produce params.  Decoding params with
the signature of the D-Bus body SHALL produce an equivalent D-Bus body.
D-Bus dict entry order is not significant.

.. list-table::
   :header-rows: 1
   :widths: 50 50

   * - D-Bus body
     - params
   * - (empty)
     - []
   * - yy 0 255
     - [0,255]
   * - bb true false
     - [true,false]
   * - nn -32768 32767
     - [-32768,32767]
   * - qq 0 65535
     - [0,65535]
   * - ii -2147483648 2147483647
     - [-2147483648,2147483647]
   * - uu 0 4294967295
     - [0,4294967295]
   * - | xx -9223372036854775808
       | 9223372036854775807
     - | ["-9223372036854775808",
       | "9223372036854775807"]
   * - tt 0 18446744073709551615
     - ["0","18446744073709551615"]
   * - dd -1.5 0.25
     - [-1.5,0.25]
   * - ss hello ""
     - ["hello",""]
   * - o /org/freedesktop/systemd1/unit/foo_2eservice
     - ["/org/freedesktop/systemd1/unit/foo_2eservice"]
   * - g a{sv}
     - ["a{sv}"]
   * - ai 0
     - [[]]
   * - as 2 a b
     - [["a","b"]]
   * - aas 2 1 a 0
     - [[["a"],[]]]
   * - (sasb) /bin/true 1 true false
     - [["/bin/true",["true"],false]]
   * - a(ss) 2 /dev/null rw /dev/zero r
     - [[["/dev/null","rw"],["/dev/zero","r"]]]
   * - a{ss} 0
     - [{}]
   * - a{sv} 2 A s x B t 18446744073709551615
     - | [{"A":["s","x"],
       | "B":["t","18446744073709551615"]}]
   * - a{sa{sv}} 1 eth0 1 mtu u 1500
     - [{"eth0":{"mtu":["u",1500]}}]
   * - a{uv} 2 7 b true 3 s x
     - [[[7,["b",true]],[3,["s","x"]]]]
   * - a{ts} 1 18446744073709551615 max
     - [[["18446744073709551615","max"]]]
   * - v v b false
     - [["v",["b",false]]]
   * - av 2 i 1 (ss) a b
     - [[["i",1],["(ss)",["a","b"]]]]
   * - | ssa(sv)a(sa(sv)) shell-1.service fail
       | 2 Description s hi
       | ExecStart a(sasb) 1 /bin/sleep 2 sleep 60 false
       | 0
     - | ["shell-1.service","fail",
       | [["Description",["s","hi"]],
       | ["ExecStart",["a(sasb)",
       | [["/bin/sleep",["sleep","60"],false]]]]],
       | []]
   * - | sa{sv}as org.freedesktop.systemd1.Service
       | 1 ExecStart a(sasbttttuii) 1
       | /bin/sleep 2 sleep 60 false
       | 1759771234567890 81234567 0 0
       | 4242 0 0
       | 0
     - | ["org.freedesktop.systemd1.Service",
       | {"ExecStart":["a(sasbttttuii)",
       | [["/bin/sleep",["sleep","60"],false,
       | "1759771234567890","81234567","0","0",
       | 4242,0,0]]]},
       | []]

Invalid Params
==============

Decoding params with signature SHALL fail.

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - signature
     - params
     - reason
   * - ss
     - ["one"]
     - too few values
   * - s
     - ["one","two"]
     - too many values
   * - i
     - ["42"]
     - string for integer
   * - i
     - [1.5]
     - real for integer
   * - d
     - ["1.5"]
     - string for double
   * - b
     - [1]
     - integer for boolean
   * - s
     - [null]
     - null for string
   * - y
     - [256]
     - out of range
   * - q
     - [-1]
     - out of range
   * - u
     - [4294967296]
     - out of range
   * - t
     - [42]
     - integer for 64-bit integer
   * - t
     - ["-1"]
     - out of range
   * - t
     - ["18446744073709551616"]
     - out of range
   * - x
     - ["9223372036854775808"]
     - out of range
   * - t
     - ["007"]
     - leading zero
   * - x
     - ["+5"]
     - leading +
   * - x
     - ["-0"]
     - negative zero
   * - t
     - [" 5"]
     - whitespace
   * - t
     - ["0x10"]
     - not decimal
   * - t
     - [""]
     - empty string
   * - s
     - ["a\\u0000b"]
     - contains U+0000
   * - o
     - ["not/a/path"]
     - invalid object path
   * - g
     - ["("]
     - invalid signature
   * - g
     - ["{sv}"]
     - dict entry outside array
   * - h
     - [5]
     - integer for descriptor object
   * - h
     - [{"fd":-1,"pid":1}]
     - negative descriptor
   * - h
     - [{"pid":1}]
     - missing fd
   * - h
     - [{"fd":5}]
     - missing pid
   * - h
     - [{"fd":5,"pid":0}]
     - invalid pid
   * - (si)
     - [["x"]]
     - too few struct members
   * - as
     - ["a"]
     - string for array
   * - a{sv}
     - [[]]
     - array for string-key dict
   * - a{uv}
     - [{}]
     - object for non-string-key dict
   * - a{uv}
     - [[[7]]]
     - dict entry without value
   * - {sv}
     - [{}]
     - dict entry outside array
   * - a{vs}
     - [[]]
     - dict key is not a basic type
   * - a{svs}
     - [{}]
     - dict entry with three members
   * - v
     - [["s"]]
     - variant without value
   * - v
     - [["s","x","y"]]
     - variant with extra element
   * - v
     - [["ss",["a","b"]]]
     - variant signature with two types
   * - v
     - [["(s",["x"]]]
     - malformed variant signature

Invalid D-Bus Bodies
====================

Encoding the D-Bus body SHALL fail.

.. list-table::
   :header-rows: 1
   :widths: 50 50

   * - D-Bus body
     - reason
   * - a{sv} 2 A s x A s y
     - duplicate dict key
   * - d nan
     - NaN
   * - d inf
     - infinite
   * - d -inf
     - infinite
   * - h 5
     - file descriptors cannot be encoded

References
**********

.. [#f1] `D-Bus Specification <https://dbus.freedesktop.org/doc/dbus-specification.html>`__

.. [#f2] `RFC 8259: The JavaScript Object Notation (JSON) Data Interchange Format, section 6 <https://datatracker.ietf.org/doc/html/rfc8259#section-6>`__

.. [#f3] `busctl(1) <https://www.freedesktop.org/software/systemd/man/latest/busctl.html>`__

.. [#f4] `sd_bus_message_dump(3) <https://www.freedesktop.org/software/systemd/man/latest/sd_bus_message_dump.html>`__

.. [#f5] `sd-bus-errors(3) <https://www.freedesktop.org/software/systemd/man/latest/sd-bus-errors.html>`__
