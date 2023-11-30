.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_30.html

30/Job Urgency
==============

This specification describes the Flux job urgency parameter.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_30.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
--------

.. include:: common/language.rst

Related Standards
-----------------

- :doc:`spec_21`


Background
----------

The Flux job *urgency* parameter reflects the job owner's idea of the job's
importance relative to other work queued on the system.  It is one factor
used by the job manager priority plugin to calculate the job *priority*,
which determines queue listing order, and the order in which jobs are
presented to the scheduler.

The urgency MAY be provided by the job owner at job submission time.
It MAY be adjusted by the job owner while the job is pending.


Implementation
--------------

Job *urgency* SHALL be an integer with range of 0 through 31.

A *guest user* MAY set or update the urgency of their own jobs to values in
the range of 0-16.

The *instance owner* MAY set or update the urgency of any job to any valid
value.

If the urgency is unspecified during job submission, a *default* initial
value of 16 is assigned.

A value of 0 indicates that the job should be *held*.  A held job is assigned
the lowest possible priority, bypassing the job manager priority plugin.
Although it remains in the queue while pending, a held job SHALL NOT be
assigned resources.

A value of 31 indicates that the job should be *expedited*.  An expedited job
is assigned the highest possible priority, bypassing the job manager priority
plugin.

If the urgency is *updated*, the job manager priority plugin SHALL be notified
so it can adjust the job's priority.

The current urgency value SHALL persist across a Flux instance restart,
therefore each change SHALL be recorded in the job's event log.
