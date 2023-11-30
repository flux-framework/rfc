.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_37.html

######################
37/File Archive Format
######################

The File Archive Format defines a JSON representation of a set or list
of file system objects.

- Name: github.com/flux-framework/rfc/spec_37.rst

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

- :doc:`spec_10`
- :doc:`spec_14`

**********
Background
**********

The File Archive Format is a container of file system objects envisioned for:

- Batch scripts, configuration files, and user defined input files embedded
  in RFC 14 jobspec.

- Stage-in and stage-out of job data sets.

*****
Goals
*****

- Allow an archive to be defined as either a *set* or a *list*, as appropriate
  for the circumstances.

- Represent regular files, directories, and symbolic links.

- Support self-contained representation of file content.

- Support JSON file content without encoding.

- Avoid requiring metadata that is not essential for reconstructing the file
  system object.

- Enable the distributed associative cache described in RFC 10 to be leveraged
  for efficient file broadcast.

- Enable efficient representation of sparse files.

**************
Implementation
**************

An archive SHALL consist of either a JSON array or a JSON dictionary of
file system objects.  File system objects MAY represent regular files,
directories, or symbolic links.

The following keys are REQUIRED in file system objects:

mode
   (integer) The file type and permissions encoded as defined for the
   ``st_mode`` member of the POSIX ``stat`` structure [#f1]_.

path
   (string) The UNIX path to the file system object.  Paths SHALL NOT contain
   ``.`` or ``..`` characters and SHALL NOT begin with a ``/``.  When the
   archive container is a dictionary, the path is derived from the dictionary
   key and SHALL NOT appear in the file system object.

The following keys are OPTIONAL in file system objects:

mtime
   (integer) The last data modification timestamp in seconds since the Epoch.

ctime
   (integer) The last file status change timestamp in seconds since the Epoch.

size
   (integer) The size of the regular file in bytes.

encoding
   (string) The encoding type used in **data** for regular files.  Possible
   values are ``utf-8``, ``base64``, ``blobvec``.

data
   Regular file content (see below) or symbolic link target (string).

Directories
===========

A directory object SHALL be represented as *empty* in the archive, thus
the **size**, **data**, and **encoding** fields SHALL NOT be present in
a directory object.

Example:

.. code:: json

  {
    "path":"appdata/phase1",
    "mode":16893,
    "mtime":1677604007,
    "ctime":1677604007,
  }


Symbolic Links
==============

A symbolic link object SHALL store the link target in the **data** field
as a UTF-8 string.  The **size** and **encoding** fields SHALL NOT be
present in a symbolic link object.

Example:

.. code:: json

  {
    "path":"src",
    "mode":41471,
    "data":"/users/fred/work/project",
  }

Regular Files
=============

Regular files are represented as follows.

Empty Files
^^^^^^^^^^^

An empty regular file (zero length or sparse with no data) SHALL be
represented with **size** set to the file size and no **encoding** or
**data** fields.

Example:

.. code:: json

  {
    "path":"data/empty",
    "mode":33204,
    "size":0,
    "mtime":1677604909,
    "ctime":1677604909
  }

JSON Content
^^^^^^^^^^^^

A regular file with JSON content MAY be represented without encoding.
In this case, **size** and **encoding** SHALL NOT be set and **data** SHALL
be set to any JSON value, array, or object.  When such a file is unarchived,
its content SHALL be a faithful JSON encoding but MAY vary in other ways
including file size.

Example:

.. code:: json

  {
    "path":"config.json",
    "mode":33204,
    "data":{
      "resource":{
        "exclude":"node42"
      }
    }
  }

Text Content
^^^^^^^^^^^^

A regular file containing text MAY be represented with UTF-8 encoding.
In this case, **size** SHALL be set to the file size, **encoding** SHALL be
set to ``utf-8``, and **data** SHALL be set to a UTF-8 string.

Example:

.. code:: json

  {
    "path":"data.csv",
    "mode":33204,
    "encoding":"utf-8",
    "data":"iteration,density\n1,35435.555\n2,356655.332\n3,5454545.500\n",
    "size":57,
  }

Literal Binary Content
^^^^^^^^^^^^^^^^^^^^^^

A regular file that requires a self-contained representation in the archive
and whose content is unknown SHALL be represented with base64 encoding.
In this case, **size** SHALL be set to the file size, **encoding** SHALL Be
set to ``base64``, and **data** SHALL be set to a base64 string.

Example:

.. code:: json

  {
    "path":"vectors.dat",
    "mode":33204,
    "encoding":"base64",
    "data":"MzU0MzUuNTU1CjIsMzU2NjU1LjMzMgozLDU0NTQ1NDUuNTAwCg=="
    "size":37,
  }

Referenced Binary Content
^^^^^^^^^^^^^^^^^^^^^^^^^

A regular file that requires content to be referenced to the associative cache
described in RFC 10 SHALL be represented with blobvec encoding.  In this case,
**size** is set to the file size, **encoding** is set to ``blobvec``, and
**data** SHALL be set to an array of 3-tuples representing file regions.
Each region is an array of three REQUIRED values:

offset
    (integer) region starting byte

size
    (integer) size of the region in bytes

blobref
    (string) RFC 10 blobref string

Example:

.. code:: json

  {
    "path": "kernel8.img",
    "size": 8194604,
    "mtime": 1674520056,
    "ctime": 1674520057,
    "mode": 33261,
    "encoding":"blobvec",
    "data": [
      [0, 1048576, "sha1-d4a09c5dd5a0d2d570066b6f13e465c73c3f9944"],
      [1048576, 1048576, "sha1-3eb8716208bc606a28948e2cf2fcce113e22b202"],
      [2097152, 1048576, "sha1-d7cc175e14044e9d9c02d908e4df4bcf80788bc9"],
      [3145728, 1048576, "sha1-34ce5050ff615ee4e2712a1f1e5b3d3df5ae6072"],
      [4194304, 1048576, "sha1-d79525827b6f326ac3d731764ee2d088bc2e5fec"],
      [5242880, 1048576, "sha1-ae1c6b3cb8eba86241fc4a761ee393dd22b833a7"],
      [6291456, 1048576, "sha1-289585f4d0c26db7ae98ecb36c04393ff32cabeb"],
      [7340032, 854572, "sha1-649d3449aa52ac46e19dc894360409d6abbeb882"]
    ],
  }

.. note::
  Only blobvec encoding is capable of representing non-empty sparse files.

.. [#f1] `sys/stat.h - data returned by the stat() function sys/stat.h <https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/sys_stat.h.html>`__; The Open Group Base Specifications Issue 7, 2018 edition IEEE Std 1003.1-2017 (Revision of IEEE Std 1003.1-2008)
