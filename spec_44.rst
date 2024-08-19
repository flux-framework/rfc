.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_44.html

44/FLUx Bootstrap Protocol
##########################

The FLUx Bootstrap (FLUB) protocol enables a Flux broker to join
a running Flux instance.

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

- :doc:`spec_3`
- :doc:`spec_6`
- :doc:`spec_13`

Background
**********

Flux brokers use a bootstrap mechanism to obtain information needed to
join a Flux instance, minimally:

- The instance size

- The overlay network topology

- The new broker's rank within the instance

- The overlay network address of the new broker's parent, whose rank
  it calculates from topology

- The public CURVE key of overlay network peers

After bootstrap, the Flux broker joins the overlay network and begins
running Flux services.

Flux brokers typically bootstrap either from static configuration files
or from a PMI service, described in :doc:`spec_13`.

A system instance bootstraps from configuration files that are replicated
on disk across a cluster.  Flux is expected to begin operations with only
the rank 0 broker online.  Other brokers may be started at any point in
time depending on system administration practices.  Some fraction are
anticipated to remain down due to problems.  A broker may rejoin a system
instance after a node crash.  All bootstrap information must be known in
advance to be represented in the configuration files.

Other Flux instances, for example a Flux-launched batch job or Slurm-launched
Flux instance, bootstrap from a PMI service.  Brokers exchange ephemeral
network addresses and CURVE public keys via the PMI protocol.  All broker
ranks must be online to participate in the exchange.  After that, a
PMI-bootstrapped instance may be set up to tolerate the loss of non-critical
brokers, but since the PMI exchange is over, there is no mechanism for lost
nodes to rejoin the instance.

The following use cases arise that cannot be easily handled by configuration
files or PMI:

#. Grow a running Flux instance by adding nodes whose identities are
   not known in advance.

#. Replace a crashed node in a PMI-bootstrapped Flux instance.

#. Starting Flux in an environment such as the cloud where PMI is
   unavailable and bootstrap information is not known a priori.

FLUB is a bootstrap mechanism that solves those problems.  It is intended
to be used after part of the instance has already bootstrapped with one
of the other methods.

Other Considerations
====================

Unlike the brokers of a Flux system instance or an instance launched in
parallel where the broker command lines are all the same, a broker added
later may have a different command line.  Therefore, select broker
attributes that may have been set on the original command line must
be shared with the new broker.

Similarly, a new broker might not have access to the instance configuration
files, so the instance's configuration object must be shared.

The ``size`` broker attribute is a constant value per RFC 3, and this constancy
is a deep assumption in the code base.  However, it is already a de facto
maximum rather than absolute size since all the brokers are not required
to be online for the duration of the instance.  A change for FLUB is that
the ``size`` now may be set to a value that exceeds the original bootstrap
size to allow room for expansion.  The additional ranks are eligible for
FLUB bootstrap.

To allow crashed nodes to be replaced with new ones, ranks that go offline
and were bootstrapped with PMI or FLUB are also made eligible for FLUB
replacement.  Ranks that were bootstrapped from configuration are not
eligible for replacement.

Caveats
=======

The following areas are problematic and may require further design:

The ``hostlist`` broker attribute is currently a constant value set following
the initial bootstrap, which enables it to be cached after first access.
Some of the code that uses it (such as log message generation) relies on the
fact that fetching the attribute does not trigger a synchronous RPC.  For now
we add placeholder hostnames to the hostlist when the instance size is greater
than the bootstrap size and leave the value constant so it can be cached.

The ``broker.mapping`` broker attribute will only include the mapping of the
initial set of broker ranks.

Goals
*****

- New brokers MUST run as the instance owner.

- New brokers MUST use a secure mechanism to connect to the Flux instance.

- Select broker attributes set on the original command line SHOULD be shared
  with the new broker.

- The instance configuration object SHOULD be shared with the new broker.

- The design SHOULD NOT impact the existing code base more than necessary.

The following are purposefully left undefined by this specification:

- How the new broker is launched.

- How the new broker's resources are added to the instance resource inventory.

- How the scheduler is notified of resource inventory changes.


Implementation
**************

A Flux broker wishing to join a Flux instance MUST obtain a valid remote
URI for any online rank.  With this URI, the broker SHALL connect to the
instance and make two RPCs in succession:

getinfo
=======

.. object:: overlay.flub-getinfo request

  The request SHALL be sent to rank 0.

  Its payload SHALL contain an empty object.

.. object:: overlay.flub-getinfo response

  The response SHALL consist of a JSON object with the following keys

  .. object:: rank

    (*integer*, REQUIRED) The rank that is assigned to the new broker.

  .. object:: size

    (*integer*, REQUIRED) The instance size.

  .. object:: attrs

    (*object*, REQUIRED) An object containing key-value pairs representing
    select broker attributes (see below).  All values SHALL have a string type.

  .. object:: config

    (*object*, REQUIRED) The entire configuration object.


key exchange
============

.. object:: overlay.flub-kex request

  The request SHALL be sent to the overlay parent rank.  The parent rank
  SHALL be calculated using information received in the previous RPC.

  The request SHALL consist of a JSON object with the following keys

  .. object:: name

  (*string*, REQUIRED) The new broker CURVE certificate name.

  .. object:: pubkey

  (*string*, REQUIRED) The new broker CURVE certificate public key.

.. object:: overlay.flub-kex response

  The response SHALL consist of a JSON object with the following keys:

  .. object:: name

  (*string*, REQUIRED) The parent broker CURVE certificate name.

  .. object:: pubkey

  (*string*, REQUIRED) The parent broker CURVE certificate public key.

  .. object:: uri

  (*string*, REQUIRED) The parent broker ZeroMQ overlay endpoint.

Example
=======

getinfo request
---------------

.. code:: json

  {}

getinfo response
----------------

.. code:: json

  {
    "rank": 3,
    "size": 16,
    "attrs": {
      "hostlist": "test[0-2],extra[3-15]",
      "instance-level": "1"
    },
    "config": {}
  }

kex request
-----------

.. code:: json

  {
    "name": "test100",
    "pubkey": "5fH%Tp1DJOO=HMWIx)V4@z%v]AWCoP(qj}Ybvoq1:"
  }


kex response
------------

.. code:: json

  {
    "name": "test1",
    "pubkey": "dFYq0s2}JTE+xGf/UcC$).c!<A00le4)<pMok2t:",
    "uri": "tcp://[::ffff:10.0.2.13]:34061"
  }
