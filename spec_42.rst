.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_42.html

42/Subprocess Server Protocol
#############################

The subprocess server protocol is used for execution, monitoring, and
standard I/O management of remote processes.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_42.rst
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
- :doc:`spec_15`
- :doc:`spec_22`
- :doc:`spec_24`

Background
**********

The subprocess server protocol is implemented in three Flux components:

.. list-table::

  * - **Name**
    - **Service Name**
    - **Notes**

  * - Flux broker
    - :program:`rexec`
    - Always available

  * - sdexec broker module
    - :program:`sdexec`
    - If systemd support is configured

  * - Flux shell
    - :program:`UID-shell-JOBID.rexec`
    - Only available to the job owner.

The primary use cases are:

#. The job execution service runs job shells on job nodes.

#. The job manager perilog plugin runs prolog/epilog scripts on job nodes.

#. The instance owner runs arbitrary processes with :program:`flux exec`.

#. Tool launch such as parallel debugger daemons using :program:`flux exec`.

In a multi-user Flux instance where a user transition is necessary in order
for the instance owner to run commands with the credentials of a guest user,
the subprocess server must be instructed to execute tasks using the IMP.  On
its own, the subprocess server can only run jobs with the credentials of the
process it is embedded within (the broker, for example).  For more detail,
refer to :doc:`RFC 15 <spec_15>`.

Goals
*****

- Run a command with configurable path, arguments, environment, and working
  directory.

- Launch the command directly, without a remote shell.

- Monitor the command for completion or error.

- Forward standard I/O.

- Optionally forward additional I/O channels.

- Provide signal delivery capability.

- Protect against unauthorized use.

Implementation
**************

exec
====

The streaming :program:`exec` RPC creates a new subprocess.  Payloads are
are defined as follows:

.. object:: exec request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: cmd

    (*object*, REQUIRED) An object that defines the command.

    See `Command Object`_ below.

  .. object:: flags

    (*integer*, REQUIRED) A bitfield comprised of zero or more flags:

    stdout (1)
      Forward standard output to the client.

    stderr (2)
      Forward standard error to the client.

    channel (4)
      Forward auxiliary channel output to the client.

Several response types are distinguished by the type key:

.. object:: exec started response

  The remote process has been started.

  The response SHALL consist of a JSON object with the following keys:

  .. object:: type

    (*string*, REQUIRED) The response type with a value of ``started``.

  .. object:: pid

    (*integer*, REQUIRED) The remote process ID returned from the UNIX
    :func:`fork` system call.

.. object:: exec stopped response

  The remote process has been stopped due to a SIGSTOP signal.
  The response SHALL consist of a JSON object with the following keys:

  .. object:: type

    (*string*, REQUIRED) The response type with a value of ``stopped``.

.. note::

  No response is generated if the process continues with SIGCONT.

.. object:: exec finished response

  The remote process is no longer running.
  The response SHALL consist of a JSON object with the following keys:

  .. object:: type

    (*string*, REQUIRED) The response type with a value of ``finished``.

  .. object:: status

    (*integer*, REQUIRED) The UNIX :func:`wait` status value.

.. object:: exec output response

  The remote process has produced output.
  The response SHALL consist of a JSON object with the following keys:

  .. object:: type

    (*string*, REQUIRED) The response type with a value of ``output``.

  .. object:: io

    (*object*, REQUIRED) Output data from the process.

    See `I/O Object`_ below.

.. object:: exec error response

The :program:`exec` response stream SHALL be terminated by an error
response per RFC 6, with ENODATA (61) indicating success.  The server MUST
NOT terminate the stream with ENODATA without first returning the
:program:`exec started` response, :program:`exec finished` response, and
:program:`exec output` responses with the EOF flag set for each open channel.
The client MAY consider it a protocol error if one of those responses is
missing and an ENODATA response is received.

Failure of the remote command SHALL be indicated in finished response
and SHALL NOT result in an error response.  Other errors, such as an
ENOENT error from the :func:`execvp` system call SHALL result in an
error response.

write
=====

The :program:`write` RPC sends data to an I/O channel of a remote process.
Valid I/O channel names MAY include ``stdin`` and auxiliary channel names
specified in the exec request command object.

.. object:: write request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: matchtag

    (*integer*, REQUIRED) The matchtag of the :program:`exec` request.

  .. object:: io

    (*object*, REQUIRED) Input data for the process.

    See `I/O Object`_ below.

This request receives no response, thus the request message SHOULD set
FLUX_MSGFLAG_NORESPONSE.  Write Requests to invalid channel names MAY be
ignored by the subprocess server.

kill
====

The :program:`kill` RPC sends a signal to a remote process.

.. object:: kill request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: pid

    (*integer*, REQUIRED) The process ID of the remote process.

  .. object:: signum

    (*integer*, REQUIRED) The signal number.

.. object:: kill response

  The successful response SHALL contain no payload.

Command Object
==============

The subprocess server command object SHALL consist of a JSON object with
the following keys:

.. object:: cwd

  (*string*, OPTIONAL) The current working directory.

  If unspecified, the server working directory SHALL be used.

.. object:: cmdline

  (*array of string*, REQUIRED) The command and its arguments.

  The array SHALL have at least one element.

.. object:: env

  (*object*, REQUIRED) A set of key-value pairs that define the
  command's environment.

  All values SHALL be of type *string*.

.. object:: opts

  (*object*, REQUIRED)  A set of key-value pairs that set subprocess options.

  All values SHALL be of type *string*.

  Options are implementation dependent and are not specified here.

.. object:: channels

  (*array of string*, REQUIRED) A list of I/O channel names.

  A socketpair SHALL be created for each channel and one end passed to
  the subprocess in an environment variable whose name is the same as
  the channel name.

I/O Object
==========

The subprocess server io object is identical to the RFC 24 Data Event context.

It SHALL consist of a JSON object with the following keys:

.. object:: stream

  (*string*, REQUIRED) The stream name such as stdout, stderr.

.. object:: rank

  (*string*, REQUIRED) An RFC 22 idset describing the source rank(s).

.. object:: data

  (*string*, OPTIONAL) Output data, encoded per :program:`encoding`.

.. object:: encoding

  (*string*, OPTIONAL) Encoding type for data.

  Possible values:

  UTF-8
    Encode as a UTF-8 string.

  base64
    Encode as a base64 string

  If not present, UTF-8 is assumed.

.. object:: eof

  (*boolean*, OPTIONAL) EOF indicator for stream.

Example
=======

exec request
------------

.. code:: json

  {
    "cmd": {
      "cwd": "/home/test",
      "cmdline": [
        "hostname"
      ],
      "env": {
        "PATH": "/bin:/usr/bin:/home/test/bin",
      },
      "opts": {},
      "channels": []
    },
    "flags": 3
  }

exec responses
--------------

.. code:: json

  {
    "type": "started",
    "pid": 1848495
  }

.. code:: json

  {
    "type": "output",
    "pid": 1848495,
    "io": {
      "stream": "stdout",
      "rank": "0",
      "data": "system76-pc\n"
    }
  }

.. code:: json

  {
    "type": "output",
    "pid": 1848495,
    "io": {
      "stream": "stderr",
      "rank": "0",
      "eof": true
    }
  }

.. code:: json

  {
    "type": "output",
    "pid": 1848495,
    "io": {
      "stream": "stdout",
      "rank": "0",
      "eof": true
    }
  }

.. code:: json

  {
    "type": "finished",
    "status": 0
  }
