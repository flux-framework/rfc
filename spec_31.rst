.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_31.html

31/Job Constraints Specification
################################

This specification describes an extensible format for the description of
job constraints.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_31.rst
  * - **Editor**
    - Mark A. Grondona <mgrondona@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_14`
- :doc:`spec_20`
- :doc:`spec_35`

Goals
*****

-  Define a format for the specification of general constraints in jobspec
-  Embed extensibility into the format to allow for growth of feature set

Background
**********

It is common practice for resource management systems to allow job
requests to contain constraints beyond the size and count of resources
that are being requested. Most often, these constraints specify a set
of allowable features or *properties* which the assigned resources must
satisfy. However more complex constraint satisfaction problems are often
supported to allow for advanced resource matching.

This RFC defines an extensible format for the specification of job
constraints in JSON.

Representation
**************

Job constraints SHALL be represented as a JSON object, which loosely
follows the `JsonLogic <https://jsonlogic.com/>`_ format of

.. code:: json

  { "operator": [ "values", ] }

where each ``value`` can also be a constraint object. This format has
several advantages:

 * The set of supported operators can be restricted for ease of implementation
   then later extended for additional functionality
 * The format allows nesting to support complex constraints
 * Simple cases can be expressed simply

The following constraint operators SHALL be supported

 - ``properties``: The set of values SHALL designate a set of required
   properties on execution targets. As a special case, if a property value
   begins with the character ``^``, then the remaining part of the value
   SHALL indicate a property that MUST NOT be included in the allocated
   resource set.

 - ``hostlist``: The set of values SHALL designate one or more sets of
   required hostnames in RFC 29 Hostlist Format.

 - ``ranks``: The set of values SHALL designate one or more sets of
   ranks compatible with the RFC 22 Idset Representation.

 - ``not``: Logical negation. Takes a single value and negates it. For
   example, to constrain a job to only those resources that do not have
   a set of attributes ``foo`` and ``bar``, the following expression could
   be used

   .. code:: json

      { "not": [{ "properties": [ "foo", "bar" ]}] }

 - ``or``: Simple logical ``or``. Evaluates true if any one of the ``value``
   arguments is true, e.g. to constrain jobs to resources that have either
   ``foo`` *or* ``bar``:

   .. code:: json

      { "or": [{ "properties": [ "foo" ]}, { "properties": [ "bar" ]}] }

 - ``and``: Simple logical ``and``.

 - ``lt``, ``le``, ``gt``, ``ge``: Numeric comparison against the value of a
   named property of an execution target, denoting *less than*, *less than or
   equal to*, *greater than* and *greater than or equal to* respectively.

   Each value SHALL be a JSON object with the REQUIRED keys ``property`` and
   ``value`` and no other key. ``property`` SHALL be a string naming a single
   property, and ``value`` SHALL be a JSON number. For example, to constrain a
   job to execution targets drawing less than 400 W

   .. code:: json

      { "lt": [ { "property": "power", "value": 400 } ] }

   An execution target satisfies one such object when it has a value for the
   named property and that value stands in the stated relation to ``value``.
   A target with no value for the named property SHALL NOT match, as for an
   absent property. A target whose value for the named property cannot be
   compared with ``value`` SHALL NOT match.

   Where more than one object is listed, an execution target satisfies the
   constraint only when it satisfies every one of them, as for the multiple
   values of ``properties``. To match any one of several comparisons, use
   ``or``.

If a constraint operator does not list any ``values``, behavior is operator
dependent.  The operator may return a match, not a match, or report an error.
However, when no ``values`` are listed for the conditional operators listed above,
``{ "or": [] }`` and ``{ "and": [] }`` are defined to always return true and
match anything.  ``{ "not": [] }`` is defined to return false and match nothing.

A comparison operator listing no values, or a value that is not a conforming
object, SHALL be an error.

There may be circumstances where it is convenient to specify a constraint object
to "always match" or "never match".  The empty value conditionals may be used
in those circumstances. i.e. ``{ "or": [] }`` to "always match" and
``{ "not": [] }`` to "never match".

In addition, an empty constraint object ``{}`` is similarly defined to
"always match".

Examples
********

Constrain resources such that all execution targets have property ``ssd``:

.. code:: json

  { "properties": [ "ssd" ] }

Constrain resources such that no execution targets with property ``slowgpu``
are allocated:

.. code:: json

  { "properties": [ "^slowgpu" ] }

or

.. code:: json

  { "not": [ { "properties": [ "slowgpu" ] } ] }

Constrain resources to have property ``ssd`` or ``huge``:

.. code:: json

  { "or": [ { "properties": [ "ssd" ] }, { "properties": [ "huge" ] } ] }

Constrain resources to include only a set of hostnames host0 and host1:

.. code:: json

  { "hostlist": [ "host[0-1]" ] }

Constrain resources to exclude hosts host0 and host1:

.. code:: json

  { "not": [ { "hostlist": [ "host[0-1]" ] } ] }

Constrain resources to a set of ``hosts host[0-1]`` and property ``ssd``:

.. code:: json

  { "and": [ { "hostlist": [ "host[0-1]" ] }, { "properties": [ "ssd" ] } ] }

Constrain resources to only those on rank 0:

.. code:: json

  { "ranks": [ "0" ] }

Constrain resources to execution targets drawing less than 400 W:

.. code:: json

  { "lt": [ { "property": "power", "value": 400 } ] }

Constrain resources to execution targets drawing at least 300 W and less than
400 W:

.. code:: json

  { "and": [ { "ge": [ { "property": "power", "value": 300 } ] },
             { "lt": [ { "property": "power", "value": 400 } ] } ] }

Constrain resources to execution targets with property ``gpu`` drawing less
than 400 W:

.. code:: json

  { "and": [ { "properties": [ "gpu" ] },
             { "lt": [ { "property": "power", "value": 400 } ] } ] }

