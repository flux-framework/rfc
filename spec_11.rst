.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_11.html

11/Key Value Store Tree Object Format v1
========================================

The Flux Key Value Store (KVS) implements hierarchical key namespaces
layered atop the content storage service described in RFC 10.
Namespaces are organized as hash trees of content-addressed *tree objects*
and values. This specification defines the version 1 format of key value
store tree objects.

-  Name: github.com/flux-framework/rfc/spec_11.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Related Standards
-----------------

-  :doc:`10/Content Storage Service <spec_10>`


Goals
-----

-  Facilitate services implementing private KVS namespaces.

-  Users may directly walk a KVS namespace, starting with a dirref.

-  Tree objects can be exchanged between Flux instances.

-  Tree objects can be parsed years after they were written (provenance).

-  Values exceeding the blob size limit (RFC 10) can be represented.

-  Tree objects exceeding the blob size limit (RFC 10) can be represented.

-  Values support an append operation.

-  A KVS namespace of arbitrary depth can be "rolled up" into one tree object.

-  Tree objects are (somewhat) self-describing.

-  Large directories are not expensive to access or update.


Implementation
--------------

In contrast to the original KVS prototype, in this specification, KVS
values are unstructured, opaque data.

All tree objects SHALL be represented as JSON objects containing three top
level names:

-  *ver*, an integer version number

-  *type*, a string type name

-  *data*, a type dependent JSON object

There are six types:

-  *valref*, data is an array of blobrefs. The concatenated blobs are
   an opaque data value (not a *val* object).

-  *val*, data is a base64 string representing opaque data.

-  *dirref*, data is an array of blobrefs. The concatenated blobs are
   interpreted as a *dir* or *hdir* object.

-  *dir*, data is a map of names to tree objects.

-  *hdir*, data is a map of integer-hashed names to *dirref* objects.

-  *symlink*, data is an object containing a target key and optionally
   a namespace.


Valref
~~~~~~

A *valref* refers to opaque data in the content store (the actual data,
not a *val* object).

::

   { "ver":1,
     "type":"valref",
     "data":["sha1-aaa...","sha1-bbb...",...],
   }


Val
~~~

A *val* represents opaque data directly, base64-encoded.

::

   { "ver":1,
     "type":"val",
     "data":"NDIyCg==",
   }


Dirref
~~~~~~

A *dirref* refers to a *dir* or *hdir* object that was serialized and
stored in the content store.

::

   { "ver":1,
     "type":"dirref",
     "data":["sha1-aaa...","sha1-bbb...",...],
   }


Dir
~~~

A *dir* is a dictionary mapping keys to any of the tree object types.

::

   { "ver":1,
     "type":"dir",
     "data":{
        "a":{"ver":1,"type":"dirref","data":["sha1-aaa"]},
        "b":{"ver":1,"type":"val","data":"NDIyCg=="}
        "c":{"ver":1,"type":"valref","data":["sha1-aaa","sha1-bbb"]},
        "d":{"ver":1,"type":"dir","data":{...},
     }
   }


Hdir
~~~~

A *hdir* is a dictionary mapping keys to any of the tree object types,
though a level of indirection. The *hdir* object is for efficiently
representing large directories.

A *dir* SHALL be converted to an *hdir* once the number of entries exceeds
a configurable *maxdirent* value. The *hdir* SHALL have a fixed number of
buckets represented by *size*, fixed when the *hdir* is created. The hash
function used to map keys to buckets SHALL be identified with *func*.
Hash buckets MAY be sparsely populated. Each hash bucket contains a single
*dirref* object.

::

   { "ver":1,
     "type":"hdir",
     "data":{
       "size":8,
       "func":"city32",
       "bucket":[
         {"ver":1,"type":"dirref","data":["sha1-aaa"]},
         ,,,,,
         {"ver":1,"type":"dirref","data":["sha1-eee"]},
         {"ver":1,"type":"dirref","data":["sha1-fff"]},
       ]
     }
   }


Symlink
~~~~~~~

A *symlink* is a symbolic pointer to a another KVS key, which may or
may not be fully qualified. Optionally, a namespace can be specified
for that key. If a namespace is not specified, the current namespace
is assumed.

Example without namespace:

::

   { "ver":1,
     "type":"symlink",
     "data":{"target":"a.a"},
   }

Example with namespace:

::

   { "ver":1,
     "type":"symlink",
     "data":{"namespace":"a","target":"b.b"},
   }
