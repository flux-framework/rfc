.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_50.html

50/Job Execution Eventlog
#########################

This specification describes the events posted to the execution eventlog
maintained by the Flux execution system in a job's guest KVS namespace.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_50.rst
  * - **Editor**
    - Mark A. Grondona <mark.grondona@gmail.com>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_16`
- :doc:`spec_18`
- :doc:`spec_21`
- :doc:`spec_41`

Background
**********

In addition to the primary job eventlog described in RFC 21, the
execution system maintains a separate eventlog at the ``exec.eventlog``
key of the job's guest KVS namespace, found under the ``guest`` key of
the job's KVS directory as described in RFC 16. Events in this eventlog
are formatted as described in RFC 18.

Unlike the events in the primary job eventlog, execution eventlog events
SHALL NOT drive job state transitions and SHALL NOT be used as input to
job state reconstruction. They provide synchronization points and
provenance for the execution phase of the job.

Events posted by the execution system itself have no prefix. Event names
prefixed with ``shell.`` are reserved for events posted by the job shell.
Such events MAY appear in the execution eventlog and their context
objects are defined by the job shell implementation.

Events beyond those listed below MAY appear in an execution eventlog.

Execution Eventlog Events
*************************

Init Event
==========

The execution system has created the guest KVS namespace and begun
initializing the job. The ``init`` event SHALL be the first event posted
to the execution eventlog.

The context SHALL be empty.

Example:

.. code:: json

   {"timestamp":1552593348.073132,"name":"init"}

Reattach Event
==============

The execution system has recovered the job after a potential restart
of the execution system or enclosing instance. This event MAY appear
one or more times in the execution eventlog after the ``init`` event.

The context SHALL be empty.

Example:

.. code:: json

   {"timestamp":1552597348.073132,"name":"reattach"}

Starting Event
==============

The execution system is about to start the job shells.

The context SHALL be empty.

Example:

.. code:: json

   {"timestamp":1552593348.088563,"name":"starting"}

Re-starting Event
=================

The execution system has successfully attached to the already executing
job shells of a recovered job. This event MAY appear after a
``reattach`` event.

The context SHALL be empty.

Example:

.. code:: json

   {"timestamp":1552597348.088563,"name":"re-starting"}

Complete Event
==============

All job shells have terminated. The execution system SHALL post this
event when it notifies the job manager of job completion. The job
manager posts the corresponding ``finish`` event to the primary job
eventlog in response to that notification, so the ``complete`` event
precedes ``finish`` and carries the same wait status.

The following keys are REQUIRED in the event context object:

status
   (integer) The job wait status as defined for the ``finish`` event
   in RFC 21.

Example:

.. code:: json

   {"timestamp":1552593348.090857,"name":"complete","context":{"status":0}}

Log Event
=========

The execution system captured output from a job shell or other process
launched on its behalf. These events are intended to aid debugging,
especially of errors that occur before the job shell has initialized its
own logging.

There are no specific requirements for the event context, but it
typically includes the component name, stream name, broker rank, and
captured data.

Example:

.. code:: json

   {"timestamp":1552593348.089211,"name":"log","context":{"component":"flux-shell","stream":"stderr","rank":"3","data":"example error message"}}

Done Event
==========

Execution is complete and the execution system has ceased writing to the
guest KVS namespace. The ``done`` event SHALL be the final event posted
to the execution eventlog, as required by RFC 41.

The context SHALL be empty.

Example:

.. code:: json

   {"timestamp":1552593348.104072,"name":"done"}
