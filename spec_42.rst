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

- Provide flow control on channels.

- Provide signal delivery capability.

- Protect against unauthorized use.

Implementation
**************

exec
====

The exec RPC creates a new subprocess. The behavior depends on whether the
RPC is initiated with a streaming or non-streaming request as defined in 
RFC 6.

Streaming request: When initiated with a streaming request, responses
(defined below) SHALL be sent until the process terminates and all output
has been delivered. If the requesting process disconnects, the subprocess
SHALL be terminated.

Non-streaming request (background mode): When initiated with a non-streaming
request, a single response SHALL be sent: either an :program:`exec started`
response if successful, or an :program:`exec error` response on failure. The
subprocess SHALL continue running as a child of the subprocess server until
it terminates or the server is shut down. The server MAY log subprocess
output and exit code to its own log stream.

.. object:: exec request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: cmd

    (*object*, REQUIRED) An object that defines the command.

    See `Command Object`_ below.

  .. object:: flags

    (*integer*, REQUIRED) A bitfield comprised of zero or more flags:

    .. note::

      The stdout, stderr, and channel flags are ignored in background mode.

    stdout (1)
      Forward standard output to the client.

    stderr (2)
      Forward standard error to the client.

    channel (4)
      Forward auxiliary channel output to the client.

    write-credit (8)
      Send ``add-credit`` exec responses when buffer space is available
      for standard input or writable auxiliary channels.

    waitable (16)
      Allow the subprocess to be waited on with a ``wait`` RPC.

  .. object:: local_flags

    (*integer*, OPTIONAL) A bitfield comprised of zero or more flags:

    stdio-fallthrough (1)
      Let subprocess inherit stdin, stdout, and stderr file descriptors
      from the subprocess server.

    no-setpgrp (2)
      Do not call setpgrp(2) before exec.  Use kill(2) instead of killpg(2)
      to signal the subprocess.

    fork-exec (4)
      Use fork(2)/exec(2) instead of posix_spawn(2) system calls to spawn
      the subprocess.

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

.. object:: exec add-credit response

  The subprocess server has more buffer space available to receive data
  on the specified channel.  The response SHALL consist of a JSON object
  with the following keys:

  .. object:: type

    (*string*, REQUIRED) The response type with a value of ``add-credit``.

  .. object:: channels

    (*object*, REQUIRED) An object with channel names as keys and
    integer credit counts as values.

  The server's initial response contains the full buffer size(s).

  These messages are suppressed if the write-credit flag was not specified.

.. object:: exec error response

When initiated with a streaming request, the :program:`exec` response
stream SHALL be terminated by an error response per RFC 6, with ENODATA
(61) indicating success. The server MUST send :program:`exec started`,
:program:`exec finished`, and :program:`exec output` responses with EOF
flag set for each open channel before terminating with ENODATA.

The client MAY consider it a protocol error if one of those responses is
missing and an ENODATA response is received.

Failure of the remote command SHALL be indicated in finished response and
SHALL NOT result in an error response.

Other errors, such as an ENOENT error from the :func:`execvp` system call
SHALL result in an error response.

When initiated with a non-streaming request, an :program:`exec error`
response SHALL NOT be sent if a failure occurs after a successful call to
:func:`execvp`.

attach
======

The :program:`attach` RPC attaches to an existing background subprocess.

.. object:: attach request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: pid

    (*integer*, REQUIRED) The process ID of the background subprocess.

  .. object:: label

    (*string*, OPTIONAL) The label of the background subprocess. If this key
    is present, the value of ``pid`` SHALL be ignored and the subprocess
    SHALL be identified by its label.

  .. object:: flags

    (*integer*, REQUIRED) A bitfield comprised of zero or more flags.

    No flags are currently supported. The flags value SHALL be ignored
    and output forwarding behavior SHALL be inherited from the original
    subprocess.

.. note::

  Output produced by the subprocess before the attach request MAY be lost
  unless the subprocess server has buffered it or logged it to its own
  log stream.

The :program:`attach` response stream SHALL follow the same format as
streaming :program:`exec` responses. The server SHALL send:

- :program:`exec attached` response to indicate successful attachment
- :program:`exec output` responses for any buffered output and subsequent
  output matching the target subprocess flags
- :program:`exec stopped` response if the subprocess is stopped
- :program:`exec finished` response when the subprocess terminates
- :program:`exec error` response with ENODATA (61) to indicate successful
  stream termination

.. object:: exec attached response

  The client has successfully attached to the subprocess.

  The response SHALL consist of a JSON object with the following keys:

  .. object:: type

    (*string*, REQUIRED) The response type with a value of ``attached``.

  .. object:: pid

    (*integer*, REQUIRED) The process ID of the subprocess.

  .. object:: flags

    (*integer*, REQUIRED) The flags that the subprocess was originally
    started with. This allows the client to determine which output streams
    and responses to expect.


If the subprocess was started with the waitable flag and has already
terminated before the attach request is processed, the server SHALL send an
:program:`exec attached` response, followed by :program:`exec output` responses
with the EOF flag set for each output stream that was being forwarded,
followed by the :program:`exec finished` response, and finally ENODATA to
terminate the stream.

.. note::

 A waitable background subprocess that is successfully attached to and
 receives the :program:`exec finished` response SHALL be considered reaped
 and cannot be waited on or attached to again.

If the requesting process disconnects, the subprocess SHALL revert to
background mode and continue running until it terminates or the server
is shut down.

.. object:: attach error response

The :program:`attach` RPC SHALL return an error response if:

- The subprocess does not exist or has exited without the waitable flag (ENOENT)
- The subprocess is not currently in background mode or already has a
  client attached (EBUSY)
- The client lacks authorization to attach to the subprocess (EPERM)

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

Input Flow Control
------------------

A client MAY track a channel's free remote buffer space :math:`L`:

- :math:`L` is initialized to zero

- Each :program:`exec add-credit` response adds credits to :math:`L`

- Each :program:`write` request subtracts the unencoded data length
  from :math:`L`.

A client MAY avoid the risk of overrunning the remote buffer by ensuring
a :program:`write` request never sends more than :math:`L` bytes of data.

To avoid unnecessary start-up delays, a client MAY "borrow credit" up to
the remote buffer size before the first :program:`exec add-credit` response.
In that case :math:`L` would have a negative value until the first
:program:`exec add-credit` response is received.

Servers SHALL implement a default input buffer size of at least 4096 bytes.
Unless the client explicitly requests a different input buffer size for the
channel, it MAY assume that 4096 bytes can be borrowed before the first
:program:`exec add-credit` response.

kill
====

The :program:`kill` RPC sends a signal to a remote process.

.. object:: kill request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: pid

    (*integer*, REQUIRED) The process ID of the remote process.

  .. object:: signum

    (*integer*, REQUIRED) The signal number.

  .. object:: label

    (*string*, OPTIONAL) The label of the remote process. If this key is
    set in the payload then the value of ``pid`` SHALL be ignored.

.. object:: kill response

  The successful response SHALL contain no payload.

wait
====

The :program:`wait` RPC waits for a subprocess to terminate and returns its
exit status. This RPC SHALL return an error if the subprocess was not started
with the waitable flag set.

.. object:: wait request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: pid

    (*integer*, REQUIRED) The process ID of the subprocess to wait for.

  .. object:: label

    (*string*, OPTIONAL) The label of the subprocess to wait for. If this key
    is present, the value of ``pid`` SHALL be ignored and the subprocess
    SHALL be identified by its label.

.. object:: wait response

  A successful response SHALL consist of a JSON object with the following key:

  .. object:: status

    (*integer*, REQUIRED) The UNIX wait status value as returned by
    :func:`waitpid`.

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

.. object:: msgchans

  (*array of object*, OPTIONAL) A list of message channels.

  Each object represents a point to point channel for Flux messages.

  .. object:: name

    (*string*, required)

    The name of the message channel.  The subprocess server SHALL set
    this name in the client environment to a URI that the client may
    connect to.

  .. object:: uri

    (*string*, required)

    A URI, accessible on the server side.  Messages received on this URI
    SHALL be transmitted to client channel.  Messages received on the client
    channel SHALL be transmitted to this URI.

.. object:: label

   (*string*, OPTIONAL) A string label for the command.

   If present, the label SHALL NOT be empty.

   The server SHOULD allow processes to be referenced by label in
   addition to process ID.

   The server MUST reject attempts to create processes with duplicate
   labels.

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
    "flags": 11
  }

exec responses
--------------

.. code:: json

  {
    "type": "add-credit",
    "channels": {
      "stdin": 4096
    }
  }

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
