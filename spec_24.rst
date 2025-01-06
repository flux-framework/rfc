.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_24.html

24/Flux Job Standard I/O Version 1
##################################

This specification describes the format used to represent
standard I/O streams in the Flux KVS.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_24.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_16`
- :doc:`spec_18`
- :doc:`spec_22`

Goals
*****

-  Incorporate task I/O streams into KVS job record.

-  Provide Flux front end tools with read access to output, write access to
   input streams.

-  Provide the Flux shell with write access to output, read access to input
   streams.

-  Use standard encoding(s) where possible, suitable for long-term archival.

-  KVS data should remain valid while the job is active (as data is appended).

-  Support textual or binary data.

-  Output should be labeled with the task rank that produced it.

-  Input and output should be labeled with a timestamp.

-  Each stream may independently indicate end-of-stream.

-  Support standard UNIX I/O streams: ``stdin``, ``stdout``, ``stderr``.

-  Support shell error and debug logging.

-  Support de-duplication of stream contents, where applicable.

Implementation
**************

Standard I/O streams SHALL be stored under two keys in the
KVS job schema: ``job.<jobid>.guest.output`` and ``job.<jobid>.guest.input``.
The values SHALL be formatted as a KVS event log (RFC 18), with events as
described below.

Header Event
============

The header event describes the input or output events that follow.
There SHALL be exactly one header event in each log, appearing first.

The following keys are REQUIRED in the event context object:

version
   (integer) Version of this format. This RFC describes version 1.

encoding
   (object) A dictionary mapping stream names (e.g. ``stdin``, ``stdout``, ``stderr``)
   to default encoding type (e.g. ``base64``, ``UTF-8``).

count
   (object) A dictionary mapping stream names (e.g. ``stdout``, ``stderr``)
   to the number of expected open streams with that name.

options
   (object) A dictionary mapping option names to values.
   See Header Options section below for the available options.

Example:

.. code:: json

   {
     "timestamp":1552593348.073045,
     "name":"header",
     "context":{
       "version":1,
       "encoding":{
         "stdout":"base64",
         "stderr":"UTF-8",
       },
       "count":{
         "stdout":2,
         "stderr":2,
       },
       "options":{
       }
     }
   }

Header Options
--------------

TBD: input distribution options.

Data Event
==========

The output event encapsulates a blob of input or output data.

The following keys are REQUIRED in the event context object:

stream
   (string) The stream name (e.g. ``stdin``, ``stdout``, ``stderr``).
   All valid stream names MUST appear as keys in the header ``encoding`` object.

rank
   (string) A string representing the rank(s) that produced the output,
   or which will read the input. The string may be an idset string (RFC
   22) or the string "all" to indicate all ranks in a job.

The following keys are OPTIONAL in the event context object:

data
   (string) The output data, encoded as described by the header.

eof
   (boolean) End of stream indicator.

The following keys are OPTIONAL in the event context object:

encoding
   (string) The encoding of this particular data event when different from
   the default encoding specified by the header event.

repeat
   (integer) Consecutive, identical data MAY be combined in one event for
   better space efficiency.  If data is combined, ``repeat`` SHALL indicate
   the number of copies represented by the event.  If ``repeat`` is not
   present, the number of copies is assumed to be 1.

The context object SHOULD contain either a ``data`` or ``eof`` key, or both.

Example:

.. code:: json

   {
     "timestamp":1552593349.1,
     "name":"data",
     "context":{
       "stream":"stdout",
       "rank":"31",
       "data":"bWVlcAo=",
       "eof":"true"
     }
   }

Redirect Event
==============

The redirect event indicates that a stream’s data has been redirected
away from the log. The caller should not expect any additional data
events in the log for that stream.

The following keys are REQUIRED in the event context object:

stream
   (string) The stream name (e.g. ``stdout``, ``stderr``). All valid stream
   names MUST appear as keys in the header ``encoding`` object.

rank
   (string) An idset string (RFC 22) representing the rank(s) that are
   redirecting output.

The following keys are OPTIONAL in the event context object:

path
   (string) Indicates the path data has been redirected to, if the data
   has been redirected to a file.

Example:

.. code:: json

   {
     "timestamp":1552593350.4,
     "name":"redirect",
     "context":{
       "stream":"stdout",
       "path":"job.output",
     }
   }

Log Event
=========

The log event supports error and debug logging from the Flux shells.

The following keys are REQUIRED in the log event context object:

level
   (integer) An Internet RFC 5424 severity level in the range of 0 (LOG_EMERG)
   to 7 (LOG_DEBUG).

message
   (string) Textual log message, encoded with UTF-8.

The following keys are OPTIONAL in the event context object:

rank
   (integer) The shell rank. If not present then the shell rank is unknown.

program
   (string) Program name that generated the log message. If not present,
   the program default is ``flux-shell``.

file
   (string) Source file from which the log message was generated.

line
   (integer) Source line from which the log message was generated.

component
   (string) A shell component or plugin name which generated the log message.
