.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_37.html

37/Flux JSON Archive
====================

This specification describes the format used to represent archives of
files and directories in JSON.

-  Name: github.com/flux-framework/rfc/spec_37.rst

-  Editor: Mark Grondona <mark.grondona@gmail.com>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.


Background
----------

When encoding one files into a JSON object, it is not problematic to
use ad hoc solutions such as storing file contents in a well known key. A
current trivial example is the placement of a batch job script into jobspec
at a well known, but arbitrary, key. However, If there is a need to store
an arbitrary number of files in JSON, or to encode a directory to JSON,
then a more formal specification may be useful.


Goals
-----

- Allow Flux utilities and jobs to store, access, and extract file and
  directory content which are stored as JSON objects.

- Allow a JSON archive to be incorporated into other JSON objects such
  as jobspec.

- Support text files, but allow future extensions to other encodings.

Implementation
--------------

A Flux JSON Archive SHALL represent a filesystem directory as a JSON object,
with a key per directory entry.

A directory entry SHALL be represented as a JSON object with the following
REQUIRED keys:

- ``mode`` : integer representation of a file ``mode_t`` as passed to
  ``chmod(2)``.

- ``content``: The contents of the directory entry.

The following keys are OPTIONAL:

- ``type``: The file type; ``file`` or ``dir``. If not set the default is
  "file".

For a directory entry of type ``file``, ``content`` is the file contents
encoded as UTF-8. If an entry of type ``file`` has contents of only JSON,
``content`` MAY be encoded as JSON instead of an escaped string.

For a directory entry of type ``dir``, ``content`` SHALL be a JSON Archive.

Examples:

- A single executable script:

  .. code:: json

    {"script.sh": {"mode": 384, "content": "#!/bin/sh\ndate;hostname\n"}}

- A small archived directory hierarchy:

  .. code:: json

    {
      "config": {
        "content": {
          "conf.json": {
            "content": {
              "tbon": {
                "tcp_user_timeout": "30s"
              }
            },
            "mode": 256
          }
        },
        "mode": 448,
        "type": "dir"
      },
      "script.sh": {
        "content": "#!/bin/sh\ndate;hostname\n",
        "mode": 384
      }
    }
    
