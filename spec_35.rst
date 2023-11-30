.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_31.html

35/Constraint Query Syntax
==========================

This specification describes a simple string syntax which can be used to
succinctly express constraints as described in RFC 31. The syntax may
also be useful in generating search and match expressions for use in other
parts of Flux.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_35.rst
  * - **Editor**
    - Mark A. Grondona <mgrondona@llnl.gov>
  * - **State**
    - raw

Language
--------

.. include:: common/language.rst

Related Standards
-----------------

- :doc:`spec_31`

Goals
-----

-  Describe and define a grammar for a simple text-based string syntax for
   generating JSON objects in the constraint format defined in RFC 31.

Background
----------

The JSON constraint format described in RFC 31 is not conducive to use
on the command line or for other cases where constraints are input by
humans. The underlying format has also shown promise as a candidate for
use in other search and matching scenarios, for example when filtering
jobs. Because of this potential for use throughout Flux, it will be
useful to define a simple query syntax which can compile to the more
verbose JSON format.

This RFC describes and defines a simple string syntax which can be used
by Flux tools and commands to generate RFC 31 compatible JSON constraint
objects.

Description
-----------

 * A constraint query string is formed by a series of terms.
 * A term has the form ``operator:operand``, where ``operator:`` is
   optional if the implementation defines a default operator. For example,
   if an implementation defines a default operator of ``name``, then
   then string ``myname`` is equivalent to ``name:myname``.
 * Terms may optionally be joined with boolean operators and parenthesis
   to allow the formation of more complex constraints or queries.
 * Boolean operators include logical AND (``&``, ``&&``, or ``and``),
   logical OR (``|``, ``||``, or ``or``), and logical negation (``not``).
   The shorthand operators allow terse strings for some implementations
   e.g. ``a|b|c``.
 * Terms separated by whitespace SHALL be joined with logical AND by default.
 * Quoting of terms SHALL be supported to allow whitespace and other
   reserved characters in ``operand``, e.g. ``foo:'this is args'``
 * A negation operator is supported in front of terms such that ``-op:operand``
   is equivalent to ``not op:operand``. Negation MAY NOT be used in front
   of general expressions, e.g. ``-(a|b)`` SHALL be a syntax error.

Grammar
-------

The basic grammar for the constraint query language is

.. code-block:: EBNF

   expr
     : expr expr
     | expr and expr
     | expr or expr
     | not expr
     | '(' expr ')'
     | '-' term
     | term

   and
     : /&{1,2}|and\b/
   or
     : /\|{1,2}|or\b/

   not
     : /not\b/

   term
     : operator':'operand
     | operand

   operator
     : STRING

   operand
     : STRING

Examples
--------

The following examples assume a default operator of ``name``

* ``foo``

.. code:: json

   {"name": ["foo"]}

* ``foo bar``

.. code:: json

   {"and": [{"name": ["foo"]}, {"name": ["bar"]}]}

* ``foo bar state:started``

.. code:: json

   {"and": [{"name": ["foo"]}, {"name": ["bar"]}, {"state": ["started"]}]}

* ``a|b|c``

.. code:: json

   {"or": [{"name": ["a"]}, {"name": ["b"]}, {"name": ["c"]}]}

* ``a|b&c``

.. code:: json

   {"or": [{"name": ["a"]}, {"and": [{"name": ["b"]}, {"name": ["c"]}]}]}

* ``(a|b)&c``

.. code:: json

   {"and": [{"or": [{"name": ["a"]}, {"name": ["b"]}]}, {"name": ["c"]}]}

* ``(a|-b)&c``

.. code:: json

   {
     "and": [
       {
         "or": [
           {
             "name": [
               "a"
             ]
           },
           {
             "not": [
               {
                 "name": [
                   "b"
                 ]
               }
             ]
           }
         ]
       },
       {
         "name": [
           "c"
         ]
       }
     ]
   }

