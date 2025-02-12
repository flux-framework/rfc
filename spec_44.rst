.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_44.html

44/Resource Events
##################

Changes to resource availability are recorded in an RFC 18 eventlog.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_44.rst
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
- :doc:`spec_18`
- :doc:`spec_21`
- :doc:`spec_22`
- :doc:`spec_29`

Background
**********

The flux-core ``resource`` service maintains an eventlog for events
pertaining to resource configuration and availability.

The initial design focuses on resource availability at the node level.
During Flux operation, resource events are posted as nodes join and leave
the instance, as system administrators drain and undrain nodes, and as
the resource set is updated.

When Flux is restarted, the eventlog stored under the ``resource.eventlog``
key is replayed to restore persistent state such node drain information.

Some events are not made persistent in the KVS as the state they represent
is not useful to recreate after a restart.

Goals
*****

- Ensure that drained nodes in a system instance remain so after a Flux
  restart.

- Provide a synchronization mechanism for other Flux components that make
  use of the resource set and resource status.

- Produce a timestamped log of events that may be useful from a
  reliability, availability, and serviceability (RAS) perspective.

- Provide sufficient context for the eventlog to be useful to an external
  monitoring system.

- Avoid excessive KVS eventlog growth

Implementation
**************

Events
======

The following events are defined.

restart
-------

The resource service has (re-)started.

This event MAY be posted to the KVS ``resource.eventlog``.

The event context SHALL contain the following keys:

.. data:: ranks

  (*string*, REQUIRED) An RFC 22 idset representing the valid execution
  targets in the instance.

.. data:: online

  (*string*, REQUIRED) An RFC 22 idset representing the execution targets
  that are currently available.

.. data:: nodelist
  :noindex:

  (*string*, REQUIRED) An RFC 29 hostlist that can be used to map execution
  targets to hostnames.

Example:

.. code:: json

 "timestamp": 1738083782.295166,
  "name": "restart",
  "context": {
    "ranks": "0-3",
    "online": "",
    "nodelist": "picl[0-3]"
  }


resource-define
---------------

The instance resource set has been defined.

This event SHALL be posted to the KVS ``resource.eventlog``.

This event is posted after the ``resource.R`` key has been populated
in the KVS and may be used for synchronization.

The event context SHALL contain the following keys:

.. data:: method

  (*string*, REQUIRED) The method used to acquire the resource set.
  This SHALL be set to one of the following values:

  configuration
    Resources are defined by system configuration.

  dynamic-discovery
    Resources were discovered through HWLOC.  The ``resource-define`` event
    may be posted late in this case since the resource set has to be gathered
    from each execution target.

  reload
    The :program:`flux resource reload` command changed the resource set.

  job-info
    The resource set was obtained from the enclosing Flux instance.

  kvs
    The resource set was already present in the kvs ``resource.eventlog`` key
    so it was simply reused.

Example:

.. code:: json

  {
    "timestamp": 1733943875.258601,
    "name": "resource-define",
    "context": {
      "method": "configuration"
    }

resource-update
---------------

The instance resource set has been updated.

Updates SHALL BE constrained to expiration updates as occurs when
the Flux instance's duration is updated in the enclosing instance.

This event SHALL be posted to the KVS ``resource.eventlog``.

.. note::
  When the duration of a running job is updated, a ``resource-update`` event
  is posted to the job eventlog.  This event is described in RFC 21.  The
  event described here has the same name but is posted to the resource eventlog.

The event context SHALL contain the following keys:

.. data:: expiration

  (*integer*, REQUIRED) Seconds since the Unix Epoch (1970-01-01 UTC).

.. code:: json

  {
    "timestamp": 1738006627.292861,
    "name": "resource-update",
    "context": {
      "expiration": 1738009133
    }
  }

drain
-----

One or more execution targets is drained.

This event SHALL be posted to the KVS ``resource.eventlog``.

.. note::
  The ``drain`` / ``undrain`` idset is required in order to uniquely identify
  the execution targets when there are multiple brokers per node, although
  such a configuration is rare and generally only used in test.
  The nodelist is also required since these events are persistent and a Flux
  system instance might be reconfigured with a different rank to hostname
  across a restart.

  When the eventlog is replayed, the resource service can check that the
  mapping is still correct.  If a discrepancy is found, it can substitute the
  first execution target rank associated with the hostname.

The event context SHALL contain the following keys:

.. data:: idset

  (*string*, REQUIRED) An RFC 22 idset representing the drained execution
  target ranks.

.. data:: nodelist

  (*string*, REQUIRED) An RFC 29 hostlist that can be used to map the idset
  execution target ranks to hostnames.

.. data:: reason

  (*string*, OPTIONAL) A message describing why the drain action was taken.

.. data:: overwrite

  (*integer*, REQUIRED) Select how this event is applied if the nodes are
  already drained.  The value SHALL be one of:

  0
    Update nothing.  Use this value if the nodes are known not to be drained.

  1
    Update the reason but not the timestamp.

  2
    Update the reason and the timestamp.

.. code:: json

  {
    "timestamp": 1733965155.6272159,
    "name": "drain",
    "context": {
      "idset": "0",
      "nodelist": "picl0",
      "reason": "unkillable processes for job ƒ4zX8UnMMxj",
      "overwrite": 0
    }
  }

undrain
-------

One or more execution targets is undrained.

This event SHALL be posted to the KVS ``resource.eventlog``.

The event context SHALL contain the following keys:

.. data:: idset
  :noindex:

  (*string*, REQUIRED) An RFC 22 idset representing the undrained execution
  target ranks.

.. data:: nodelist
  :noindex:

  (*string*, REQUIRED) An RFC 29 hostlist that can be used to map the idset
  execution target ranks to hostnames.

.. code:: json

  {
    "timestamp": 1734395501.1793933,
    "name": "undrain",
    "context": {
      "idset": "0",
      "nodelist": "picl0"
    }
  }

online, offline
---------------

One or more execution targets has transitioned to online or offline.

This event MAY be posted to the KVS ``resource.eventlog``.

The event context SHALL contain the following keys:

.. data:: idset
  :noindex:

  (*string*, REQUIRED) An RFC 22 idset representing the execution target ranks.
  Ranks can be mapped to hostnames using the ``nodelist`` key from the
  most recent ``restart`` event.

.. code:: json

  {
    "timestamp": 1738007023.0803587,
    "name": "online",
    "context": {
      "idset": "1-15"
     }
  }

.. code:: json

  {
    "timestamp": 1738007048.9008777,
    "name": "offline",
    "context": {
      "idset": "12"
    }
  }

torpid, lively
--------------

One or more execution targets has transitioned to torpid or lively.
A broker is considered torpid if it hasn't been heard from in some period
of time, by default 30s, and hasn't yet been marked offline.
A broker is considered lively if it is not torpid.

This event MAY be posted to the KVS ``resource.eventlog``.

The event context SHALL contain the following keys:

.. data:: idset
  :noindex:

  (*string*, REQUIRED) An RFC 22 idset representing the execution target ranks.
  Ranks can be mapped to hostnames using the ``nodelist`` key from the
  most recent ``restart`` event.

.. code:: json

  {
    "timestamp": 1738007023.0803587,
    "name": "torpid",
    "context": {
      "idset": "7"
     }
  }

.. code:: json

  {
    "timestamp": 1738007023.0803587,
    "name": "lively",
    "context": {
      "idset": "7"
     }
  }

truncate
--------

The in-memory eventlog MAY be configured with a maximum size to prevent
unbounded growth. When events are dropped to maintain this size, they SHALL be
replaced with a ``truncate`` event summarizing the lost state. The timestamp
of the ``truncate`` event SHALL be that of the most recently dropped event. A
``truncate`` event SHALL always be the first event in a truncated eventlog.

This event SHALL NOT be posted to the KVS ``resource.eventlog``.

The event context SHALL contain the following keys:

.. data:: online
  :noindex:

  (*string*, REQUIRED) An RFC 22 idset representing the execution targets
  that are currently available.

.. data:: torpid
  :noindex:

   (*string*, REQUIRED) An RFC 22 idset representing the execution targets
   that are currently torpid.

.. data:: drain
  :noindex:

   (*object*, REQUIRED) A JSON object representing the currently drained
   ranks, and the timestamp and reason associated with the applicable ``drain``
   events. Each key in the ``drain`` object SHALL be an RFC 22 idset which
   represents the execution targets to which the entry applies, and each value
   SHALL contain the following keys:

   .. data:: timestamp
     :noindex:

   (*float*, REQUIRED) The drain timestamp.

   .. data:: reason
     :noindex:

   (*string*, REQUIRED) The drain reason.

.. data:: ranks
  :noindex:

  (*string*, OPTIONAL) An RFC 22 idset representing the valid execution
  targets in the instance. This key is only present if a ``restart``
  event has been truncated.

.. data:: nodelist
  :noindex:

  (*string*, OPTIONAL) An RFC 29 hostlist that can be used to map execution
  targets to hostnames. This key is only present if a ``restart`` event has
  been truncated.

.. data:: discovery-method
  :noindex:

   (*string*, OPTIONAL) The discovery method of the ``resource-define`` event
   if that event has been truncated.

.. data:: R
  :noindex:

   (*object*, OPTIONAL) This key SHALL be set when the ``resource-define``
   event has been truncated.


Journal
=======

Watching the KVS `resource.eventlog` may be insufficient to capture all the
events that are of interest, since only a subset are posted there, as
noted above.

The *resource journal* is a streaming RPC that can be used to obtain all
the resource events.

A sentinel, described below, demarcates historical events from current ones.

journal request
---------------

The ``resource.journal`` request has no payload.

journal response
----------------

The response SHALL have a JSON payload with the following keys:

.. data:: events

  (*array*, REQUIRED) A list of RFC 18 events in object format.  If the array
  is empty, the response SHALL be interpreted as the sentinel mentioned above.

.. data:: R

  (*object*, OPTIONAL) This key SHALL be set when the ``events`` array
  contains a ``resource-define`` event.

Example:

.. code:: json

  {
    "events": [
      {
        "timestamp": 1738091754.2095973,
        "name": "restart",
        "context": {
          "ranks": "0-63",
          "online": "",
          "nodelist": "test[0-63]"
        }
      }
    ]
  }
  {
    "events": [
      {
        "timestamp": 1738091754.6308477,
        "name": "online",
        "context": {
          "idset": "0"
        }
      }
    ]
  }
  {
    "events": [
      {
        "timestamp": 1738091755.6784651,
        "name": "online",
        "context": {
          "idset": "1,4,6,8,13,17,21,23,26,29-30"
        }
      }
    ]
  }
  {
    "events": [
      {
        "timestamp": 1738091755.7908268,
        "name": "online",
        "context": {
          "idset": "3,7,9,12,14,18-19,24,27"
        }
      }
    ]
  }
  {
    "events": [
      {
        "timestamp": 1738091755.8945713,
        "name": "online",
        "context": {
          "idset": "2,5,10-11,15-16,20,22,25,28,31-32"
        }
      }
    ]
  }
  {
    "events": [
      {
        "timestamp": 1738091756.397182,
        "name": "resource-define",
        "context": {
          "method": "dynamic-discovery"
        }
      }
    ],
    "R": {
      "version": 1,
      "execution": {
        "R_lite": [
          {
            "rank": "0-63",
            "children": {
              "core": "0-5"
            }
          }
        ],
        "starttime": 0,
        "expiration": 0,
        "nodelist": [
          "test[0-63]"
        ]
      }
    }
  }
  {
    "events": [
      {
        "timestamp": 1738091756.8738723,
        "name": "online",
        "context": {
          "idset": "34,36-39,44-46,49-52,54,56,58,60-62"
        }
      }
    ]
  }
  {
    "events": [
      {
        "timestamp": 1738091756.9749432,
        "name": "online",
        "context": {
          "idset": "33,35,40-43,47-48,53,55,57,59,63"
        }
      }
    ]
  }
  {
    "events": []
  }


cancellation
------------

A ``resource.journal-cancel`` RPC is available to cancel the stream as
described in RFC 6.  Alternatively, the client MAY simply disconnect
and the effect is the same.
