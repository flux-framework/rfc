.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_31.html

31/Job Constraints Specification
================================

This specification describes an extensible format for the description of
job constraints.

-  Name: github.com/flux-framework/rfc/spec_26.rst
-  Editor: Mark A. Grondona <mgrondona@llnl.gov>
-  State: raw

Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.

Related Standards
-----------------

-  :doc:`14/Canonical Job Specification <spec_14>`
-  :doc:`20/Resource Set Specification Version 1 <spec_20>`

Goals
-----

-  Define a format for the specification of general constraints in jobspec
-  Embed extensibility into the format to allow for growth of feature set

Background
----------

It is common practice for resource management systems to allow job
requests to contain constraints beyond the size and count of resources
that are being requested. Most often, these constraints specify a set
of allowable features or *properties* which the assigned resources must
satisfy. However more complex constraint satisfaction problems are often
supported to allow for advanced resource matching.

This RFC defines an extensible format for the specification of job
constraints in JSON.

Representation
--------------

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

In this version of the RFC, only the following constraint operators SHALL be
supported

 - ``properties``: The set of values SHALL designate a set of required
   properties on execution targets. As a special case, if a property value
   begins with the character ``^``, then the remaining part of the value
   SHALL indicate a property that MUST NOT be included in the allocated
   resource set.

Future extensions
~~~~~~~~~~~~~~~~~

The following constraint operators MAY be supported. If a job is submitted
using these constraint operators, and the operators are not supported by
the instance, then the job SHALL be rejected with an appropriate error
message:

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

Examples
--------

Constrain resources such that all execution targets have property ``ssd``:

.. code:: json

  { "properties": [ "ssd" ] }

Constrain resources such that no execution targets with property ``slowgpu``
are allocated:

.. code:: json

  { "properties": [ "^slowgpu" ] }


