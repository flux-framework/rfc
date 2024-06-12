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

FLAN SHALL be implemented in two parts:

The jobtap plugin
  A shared library based on the API defined in 
  `flux-jobtap-plugins(7) <https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man7/flux-jobtap-plugins.html>`_
  that streams the jobids of notification-enabled jobs to the Python driver.

The Python driver
  A Python process used for tracking notification-enabled jobs through the job
  life cycle. Started by the system instance owner on the node containing the rank 
  0 broker in a cluster, it asynchronously monitors the events of all notification-enabled
  jobs. It attaches callbacks to certain events and sends notifications.

Initial Request
---------------

After the jobtap plugin has been loaded in the job-manager, the Python driver 
SHALL send a ``notify.enable`` streaming RPC request to the jobtap plugin 
at initialization.

The ``notify.enable`` request has no payload.

At initialization the Python driver SHALL create a kvs subdirectory, ``notify``.
Should this directory already exist, the Python driver SHALL NOT crash. The
Python driver SHALL traverse the existing directory and record the jobids in it.
The Python driver SHALL reconcile the jobids in the KVS with the jobids in the
responses to the initial RPC. 

Initial Responses
-----------------

The jobtap plugin SHALL keep a record of jobids for jobs that are ACTIVE and
notification-enabled. On initialization, all of the jobids in this record
SHALL be sent as individual responses to the Python driver.

jobid
  As defined in :doc:`spec_19`, a single jobid for a notification-enabled job.

.. note::
  The initial responses are intended to restore state should the Python driver
  crash.

Additional Responses
--------------------

The jobtap plugin SHALL continue to send responses to the initial 
``notify.enable`` RPC request whenever notification-enabled jobs enter the
NEW state. The jobtap plugin SHALL add these jobids to its record 
of ACTIVE, notification-enabled jobs.

For each response received by the Python driver, the driver SHALL create a 
KVS subdirectory, ``notify.<jobid>``. In this directory the driver SHALL
insert keys representing the job events for which users have requested a 
notification. These keys values SHALL be empty. The key SHALL be deleted
after the corresponding notification is sent. 

The Python driver MUST then asynchronously monitor the job as it reaches
events of interest.

When the job reaches an event of interest, the Python driver SHALL 
generate a notification and send it to the user. The Python
driver SHALL subsequently delete the corresponding key in the KVS, 
``notify.<jobid>.<state>``.

The ``notify.<jobid>`` KVS subdirectory SHALL be deleted when the job reaches 
an INACTIVE state. If the ``notify.<jobid>`` directory is non-empty upon 
reaching the INACTIVE state, this indicates some notifications have been missed.
The Python driver SHALL send a final notification to the user documenting 
that their notification-enabled job has reached an INACTIVE state.

.. note::
  This design is intended to ensure that no double-notifications are sent upon
  the restart of the Python script, the jobtap plugin, or the job-manager.

Error Response
--------------

If an error response is returned to ``notify.enable``, this indicates that the 
jobtap plugin is not loaded in the job-manager. The Python driver SHALL exit 
immediately, and print an appropriate error message.

Disconnect Request
------------------

If a disconnect request is received by the jobtap plugin, this indicates the
Python driver has exited. The jobtap plugin SHALL continue to add notification-
enabled jobs to its record as they enter the NEW state. When the Python
driver reconnects, the jobtap plugin SHALL respond to its initial ``notify.enable``
RPC request with a response RPC for each jobid that is notification-enabled.

User Interface
**************

Users SHALL create notification-enabled jobs by specifying an attribute in their
job's jobspec. Jobspec attributes are defined in :doc:`spec_25`

Basic Use Case
--------------

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
------------------

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

Restarting the job-manager
--------------------------

In the event the job-manager crashes or is shut down the Python driver SHALL exit
immediately and log an error. 

Flux does not currently support restarting with running jobs. However, on a system
restart, all events for all ACTIVE jobs are replayed. This means that when each
notification-enabled job reaches the NEW event, the jobtap plugin SHALL
send a streaming RPC response and record the jobid. The Python driver, upon 
receiving a new jobid MUST ensure that the jobid does not have
a previous entry in the KVS. Since the KVS is reloaded on a restart, any outstanding
notifications SHALL have corresponding keys there. If a jobid received by the Python
driver already has a KVS subdirectory, the Python driver SHALL ignore the job's 
event notification requests in the jobspec and only send notifications that
correspond with the keys in the KVS. This prevents a double-notification of the user
for the same job state on a restart of the job-manger or FLAN service.

Expiration of notifications
---------------------------

In certain cases, a restart of the service may be delayed such that events of interest
on notification-enabled jobs are long past. FLAN MAY support an "expiration" setting
which would stop any notification from final delivery if a set amount of time had
passed since the event.

Subinstance notifications
-------------------------

Due to the recursive launch feature of Flux, users may wish to have notifications 
for states of batch jobs that are not at the system-instance level. This MAY NOT 
be supported in FLAN v1.

Invalid jobspec attributes
--------------------------

FLAN MAY eventually provide a plugin for validating the advanced use 
cases detailed above. In the interim, if a user tries to utilize the advanced 
case and provide junk keys or values, FLAN SHALL defer to default mode.

