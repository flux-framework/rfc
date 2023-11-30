.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_31.html

36/Submission Directives
========================

This specification describes a method for embedding options and other
directives into a file for use by utilities that submit jobs to Flux.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_36.rst
  * - **Editor**
    - Mark A. Grondona <mgrondona@llnl.gov>
  * - **State**
    - raw

Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.

Goals
-----

- Describe an understandable and easily processed syntax for embedding
  job submission utility options and other directives into a file or
  script.
- Support the operation of legacy batch scripts which require such a syntax
- Support arbitrary source file comment syntax
- Encourage directives to be grouped together in source files
- Allow future extensions to increase the versatility of the syntax

Background
----------

Many extant and moribund computational batch systems support embedding job
submission options within a submitted batch script. For example LoadLeveler's
``#@`` directive, PBS ``#PBS`` directives, LSF ``#BSUB``, and Slurm
``#SBATCH``. Though the proclivity of these systems to support embedded
options may result in unnecessary copies of batch scripts, the practice
is well established and many users are now dependent on this behavior.


Description
-----------

 * An option, flag, or other directive embedded in a file or script SHALL
   be known as a *submission directive*.
 * A submission directive SHALL be indicated by a line which starts with 
   a prefix of non-alphanumeric characters followed by a tag ``FLUX:`` or
   ``flux:``. The prefix+tag SHALL be known as the *directive sentinel*.
 * All valid sentinels SHALL match the regular expression
   ``"^([^\w]*)(flux|FLUX):``.
 * All submission directives in a file MUST use the same sentinel.
 * Directive processing SHALL be halted at the first non-blank line which
   does not start with the same prefix as the initial directive. This rule
   encourages directives to be grouped together, but allows directives to
   be interspersed with other lines as long as the prefix remains the same.
   e.g.:  ::

      # flux: -N 4 -c 2
      # Set job name:
      # flux: --job-name

 * An error SHALL be raised if a directive is detected after directive
   processing has stopped. e.g. the following SHALL raise an error: ::

      # flux: -N4
      # flux: -c2
      echo hello, world
      # flux: --queue=batch

 * A submission directive immediately follows the sentinel until end of line.
 * The character ``#`` MAY be used as a comment character within a directive,
   in which case the ``#`` character until end of line SHALL be ignored: ::

      # flux: -N4 # -c2 : comment out for now

 * Leading and trailing whitespace in the directive part SHALL be ignored,
   unless otherwise quoted.
 * POSIX shell style quoting [#f1]_ SHALL be supported in directives.
 * Triple quoted strings SHALL be supported in directives to allow inclusion
   of quotes and newlines without escaping. For example: ::

   # flux: --setattr=user.foo="""{"key": 42}"""
   # flux: --setattr=user.bar='''It's a "job"'''

 * When a triple quoted string is used for a multiline literal, the following
   rules SHALL apply:

   - opening and closing triple quotes MUST be at the end of the line
   - all lines MUST begin with the directive sentinel
   - the newline after the opening quote SHALL be ignored
   - matching indentation SHALL be stripped from the result

   for example: ::

      # flux: --setattr=user.conf="""
      # flux: [config]
      # flux:   item = "foo"
      # flux: """

   becomes the literal ``'--setattr=user.conf=[config]\n  item = "foo"\n'``.

 * Directives that start with ``-`` SHALL be reserved as options to the
   processing submission utility.

Examples
--------

 * Directives in a shell script, maximum nostalgia mode:

 .. code-block:: sh

   #!/bin/sh
   #FLUX: -N4                  # Request four nodes
   #FLUX: --queue=batch        # Submit to the batch queue
   #FLUX: --job-name=app001    # Set an explicit job name
   flux mini run -N4 app

 * Directives embedded in a multiline Python docstring, 
   including a multiline directive:

 .. code-block:: python

   #!/usr/bin/env python3
   def main():
       """
       flux: -N4
       flux: --queue=batch
       flux: --job-name="my python job"
        
       # Set some arbitrary user data:
       flux: --setattr=user.data='''
       flux: x, y, z
       flux: a, b, c
       flux: '''
       """
       run()

 * Directives embedded in a Lua script. Note: multiple options can be
   included in a single directive:

 .. code-block:: lua

   #!/usr/bin/lua
   --
   -- flux: -N1 --exclusive
   -- flux: --output=job.out
   local app = require 'app'
   app.run()

 * Directives can be mixed with non-directive comments if they share
   a common prefix:

 .. code-block:: sh

   #!/bin/sh
   # Set flux directives
   #FLUX: -N1
   # Set job name:
   #FLUX: --job-name=test
   hostname; date

 .. code-block:: python

   #!/usr/bin/env python3
   """
   flux: --nodes=4

   Set an arbitrary value in jobspec:
   flux: --setattr=user.foo="hello, earth"
   """

 * Use single quotes to quote double quote:

 .. code-block:: sh

   # flux: --setattr=user.data='{"option": "arg"}'

 * Use triple quotes to quote a literal with both single and double quotes:

 .. code-block:: sh

  # flux: --job-name='''It's a "job"'''
   
 * A stray or orphan directive, which results in an error before submission:

 .. code-block:: sh

   #!/bin/sh
   #FLUX: -N1
   hostname; date
   #FLUX: --job-name=test


.. [#f1] `Shell Command Language: Quoting <https://pubs.opengroup.org/onlinepubs/009604499/utilities/xcu_chap02.html>`__; The Open Group Base Specifications Issue 6; IEEE Std 1003.1, 2004 Edition
