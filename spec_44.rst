.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_28.html

44/Flux Library for Adaptable Notifications Version 1
###########################################################

This specification describes the Flux service that allows users to
receive external notifications for events in a Flux job.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_44.rst
  * - **Editor**
    - William Hobbs <wihobbs@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_14`
- :doc:`spec_21`
- :doc:`spec_25`

Background
**********

Toward the goal of supporting users who run batch jobs with variable end time
dependent on queues, runtime, and other factors, the Flux Library for Adaptable
Notifications (FLAN) provides event-driven functionality that sends external
notifications of job events. 

Terminology
***********

These terms may have broader meaning in other RFCs or the Flux project. To
avoid confusion, below is a glossary of terms as they apply in this document.

Notification
  An email or other notification triggered by FLAN but whose ultimate delivery
  is handled by an external service.

Notification-enabled jobs
  Jobs that include a jobspec attribute requesting a notification for certain
  events in the job's life cycle. For a more detailed definition of job events,
  refer to :doc:`spec_21`.


Requirements
************

 - By default in a system-instance, do not notify a user of any job events.
   Allow the user to override this default with a jobspec attribute,
   ``system.notify``.
 - Support notification after any event of the job, where events are defined in
   :doc:`spec_21`.
 - Support email for end user notification delivery.
 - Allow for extensibility via plugins to support more end user notification 
   delivery services, such as Slack and Mattermost. The implementation of
   plugins for any service other than email is not a requirement.
 - Utilize as few resources as possible in the Flux job-manager. Under no
   circumstances will a notification block any stage or event of a Flux job.
 - Provide configurable rate-limiting to ensure users can never be overwhelmed
   by notifications.

Implementation 
**************

FLAN SHALL be implemented by a Python service that MAY be started under
``systemd``.

Introduction
============

The Flux job-manager journal of events (JoE) is an interface that streams job
events in real-time for jobs in a Flux instance. The JoE can be configured to
send all completed events in addition to streaming real-time events. The JoE
includes annotations such as jobspec and R where appropriate. 

The Flux Library for Adaptable Notifications (FLAN) provides a server that
opens a streaming RPC request to the JoE, receives events from the JoE, stores
jobspec, event logs, and resource sets by jobid for all active jobs, and allows
for clients to asynchronously perform operations (such as send emails) based on
these events. FLAN implements an event dispatcher to handle batches of events
based on a timer, allowing for a massive number of events to be handled
semi-synchronously without blocking the receipt of more RPC responses. Since
FLAN is run as a separate python script alongside a Flux instance, it can never
block the job-manager or other critical Flux services and need not be run under
the system ``flux python``, allowing for clients to take advantage of the latest
Python features. FLAN must be run under the instance owner credentials but
needn't be run on the same node as the rank 0 Flux broker.

Initial Request
===============

FLAN SHALL open a streaming RPC request to the JoE. FLAN SHALL request the full
journal, including completed events.

Initial Response(s)
===================

An "initial response" is any response prior to the JoE's "sentinel," which
indicates that the backlog has completed transmission. 

Initial responses are per-jobid and can include multiple events. FLAN SHALL
store the annotations (jobspec, R) per jobid and process each event.

Event Dispatcher
================

Instead of handling each event sequentially, events shall be queued and handled
in batches by the event dispatcher. The event dispatcher SHALL be a Python
class containing a queue of events to process. The event dispatcher SHALL
process these events after receiving a signal from the reactor's timer watcher.
The timer watcher SHALL have a configurable delta (time between wake-ups).

Upon waking up, the event dispatcher shall determine if an event is "of
interest," and process the event if so. Only the most recent event for a given
job SHALL be processed. Processing of the event involves clients of the FLAN
server completing any process they wish on an event, such as sending an email.

On the initial run of the event dispatcher, FLAN SHALL compare the events in
its queue to a record in the KVS of "handled" events, and ignore "handled"
events. The initial run of the event dispatcher SHALL block subsequent runs.
For each subsequent iteration of the event dispatcher, FLAN SHALL write to the
KVS a record of the events it has processed before the event dispatcher goes to
sleep. 

Subsequent Responses
====================

Subsequent responses from the JoE shall be queued in the event dispatcher in
real-time, and processed when the dispatcher wakes up. A record of jobspec, R,
and eventlog for each event SHALL be stored, and the record removed by the
event dispatcher when it receives the `clean` event for a job.

User Interface
**************

Users SHALL create notification-enabled jobs by specifying an attribute in their
job's jobspec. Jobspec attributes are defined in :doc:`spec_25`

Basic Use Case
==============

Users SHALL add the following attribute to their jobspec:

.. code-block:: json

  {
    "attributes": { 
      "system": {
        "notify": "default"
      }
    }
  }

The default behavior SHALL be to send a notification via email to the user
when the job reaches the START and FINISH events.

Advanced Use Cases
==================

Only the basic use case SHALL be supported in v1.

The ``system.notify`` jobspec attribute SHALL accept a dictionary containing some
or all of the following values:

.. code-block:: json

  {
    "attributes": { 
      "system": {
        "notify": {
          "service": "slack",
          "handle": "elvis",
          "include": ["R", "eventlog", "return_code"],
          "states": ["start", "prolog_finish"]
        }
      }
    }
  }

Edge Cases
**********

These edge cases MAY be supported in FLAN v1.

Expiration of notifications
===========================

In certain cases, a restart of the service may be delayed such that events of interest
on notification-enabled jobs are long past. FLAN MAY support an "expiration" setting
which would stop any notification from final delivery if a set amount of time had
passed since the event.

