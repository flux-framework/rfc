.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_41.html

41/Job Information Service
##########################

The Flux Job Information Service provides convenient, read-only access to
KVS job data for job owners.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_41.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_15`
- :doc:`spec_16`
- :doc:`spec_18`
- :doc:`spec_20`
- :doc:`spec_21`
- :doc:`spec_24`
- :doc:`spec_25`

Background
**********

Job info is stored in a job-specific KVS directory as described in
:doc:`RFC 16 <spec_16>`.  Among the keys stored for each job are:

.. list-table::
  :widths: 25 75

  * - **J**
    - signed jobspec submitted by the user (:doc:`RFC 15 <spec_15>`)
  * - **jobspec**
    - unwrapped jobspec from J (:doc:`RFC 25 <spec_25>`), potentially modified
      at ingest
  * - **eventlog**
    - primary job eventlog (:doc:`RFC 21 <spec_21>`)
  * - **R**
    - resource set allocated to job (:doc:`RFC 20 <spec_20>`)
  * - **guest.exec.eventlog**
    - exec system eventlog
  * - **guest.input**
    - job input (:doc:`RFC 24 <spec_24>`)
  * - **guest.output**
    - job output (:doc:`RFC 24 <spec_24>`)

While the job is running, the ``guest`` key in the job directory is a
symbolic link to a private KVS namespace that may be read or written by
the job owner.  All KVS accesses from the job are redirected to the private
namespace.  This supports the job shell running as the guest user, and also
allows job applications and user-invoked tools to use the KVS.

Once the job becomes inactive, the private namespace is deleted and the
``guest`` link becomes a directory in the primary KVS namespace that contains
a snapshot of the private namespace's content.  At this point only the
instance owner may directly access this information.

The main purpose of the job info service is to give job owners convenient,
read-only access to the data in their KVS job directory.

Goals
*****

- Provide read-only access to all keys in a given KVS job directory.

- Restrict access to the job owner and the Flux instance owner.

- Provide scalability and performance comparable to direct KVS access.

- Hide the complexity of watching eventlogs across the ``guest`` transition
  described above.

Implementation
**************

The job info service SHOULD be distributed across all broker ranks to
avoid creating a bottleneck at the leader broker.

Job information requests below are for a single job ID.  If a request was
not sent by the instance owner or the job owner, it SHALL fail with error 1,
"Operation not permitted" (EPERM).

Internally, the job information service MAY determine the *job owner* by
fetching the primary job eventlog and reading the userid from the ``submit``
event context.

Lookup
======

The :program:`job-info.lookup` RPC fetches one or more job info keys from
the KVS.

If a failure occurs while looking up any of the keys, the entire request
SHALL fail.

The RPC payloads are defined as follows:

.. object:: job-info.lookup request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: id

    (*integer*, REQUIRED) The job id.

  .. object:: keys

    (*array of string*, REQUIRED) List of keys.

    Keys SHALL be specified relative to the job directory, and SHALL use
    period ``.`` as the path delimiter.

  .. object:: flags

    (*integer*, REQUIRED) A bitfield comprised of zero or more flags:

    json_decode (1)
      For lookups of R or jobspec, return the field as a decoded
      JSON object instead of a string.  This flag has no effect on
      other keys.

    current (2)
      For lookups of R or jobspec, return the current version. The
      current version SHALL be computed by applying any
      resource-update or jobspec-update events that have been posted
      to the job eventlog, as described in RFC 21.

.. object:: job-info.lookup response

  The response SHALL consist of a JSON object with the following keys:

  .. object:: id

    (*integer*, REQUIRED) The job id from the request.

  .. object:: keys...

    Additional keys correspond to the keys in the request.

    Values are the KVS values associated with the keys.  Values are
    encoded as strings, except in special cases indicated by flags
    in the request.

Eventlog Watch
==============

The :program:`job-info.eventlog-watch` streaming RPC tracks events posted to
an RFC 18 eventlog.

The RPC stream SHALL be terminated with error 61, "No data available"
(ENODATA) when one of the following conditions is met:

- The RPC is canceled with a :program:`job-info.eventlog-watch-cancel` request.
- The job becomes inactive
- A context-specific terminating event is posted to the eventlog:

.. list-table::
  :widths: 25 75

  * - **eventlog**
    - clean
  * - **guest.exec.eventlog**
    - done
  * - **guest.output**
    - data with eof=true on all streams and all ranks
  * - **guest.input**
    - data with eof=true


The RPC payloads are defined as follows:

.. object:: job-info.eventlog-watch request

  The request SHALL consist of a JSON object with the following keys:

  .. object:: id

    (*integer*, REQUIRED) The job id.

  .. object:: path

    (*string*, REQUIRED) The eventlog key.

    The key SHALL be specified relative to the job directory, and SHALL use
    period ``.`` as the path delimiter.

  .. object:: flags

    (*integer*, REQUIRED) A bitfield comprised of zero or more flags:

    waitcreate (1)
      If key does not exist yet, wait for its creation before responding.

.. object:: job-info.eventlog-watch response

   Each non-error response SHALL consist of a JSON object with the following
   keys:

   .. object:: event

     (*string*, REQUIRED) Exactly one :doc:`RFC 18 <spec_18>` eventlog entry,
     including trailing newline.

.. object:: job-info.eventlog-watch-cancel request

  Cancel a :program:`job-info.eventlog-watch` request, as described in
  :doc:`RFC 6 <spec_6>`.

  .. object:: matchtag

    (*integer*, REQUIRED) The matchtag of the request to be canceled.
