.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_2.html

2/Flux Licensing and Collaboration Guidelines
=============================================

The Flux framework is a family of projects used to build site-customized
resource management systems for High Performance Computing (HPC) data
centers. This document specifies licensing and collaboration guidelines
for Flux projects.

-  Name: github.com/flux-framework/rfc/spec_2.rst

-  Editor: Jim Garlick <garlick@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Goals
-----

A Flux project is defined as software which implements a resource
manager function, or is otherwise tightly coupled to the resource
manager or its communications framework. Flux projects are expected
to have contributors spanning academic institutions, government
laboratories, companies, and individuals.

Our licensing and collaboration guidelines must balance the following goals:

-  Encourage participation in the Flux community by all interested parties.

-  Ensure that the Flux community remains healthy and active by
   welcoming contributions, vetting changes in the open,
   collectivizing ownership, and distributing responsibility.

-  Allow Flux projects to leverage a large body of open source,
   including from the HPC ecosystem [#f1]_.

-  Ensure that end users have full source code to their particular
   Flux system to maximize their ability to self-support and obtain
   help from the Flux community.

-  Ensure that successful Flux systems are fully replicatable
   and redistributable across platforms and sites.

-  Facilitate the use of Flux and its programming interfaces by external
   projects such as applications, application runtimes, and tools, that are
   distributed under a wide variety of open source and commercial licenses.


Design
------


Collaboration Model for Flux Projects
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Flux projects SHALL adopt the Collective Code Construction Contract
   (C4.1) described in Flux RFC 1.

-  It is RECOMMENDED that Flux projects be hosted under the
   Github `flux-framework <https://github.com/flux-framework>`__ organization,
   including use of the Github tracker as outlined in C4.1.

-  It is RECOMMENDED that Flux projects be discussed on the Flux
   discussion list <flux-discuss@lists.llnl.gov>.


License for Flux Projects
~~~~~~~~~~~~~~~~~~~~~~~~~

-  Flux projects SHALL be licensed under the `GNU Lesser General Public License (LGPL) version 3 <https://www.gnu.org/licenses/lgpl-3.0.en.html>`__.

-  Flux projects are RECOMMENDED to permit redistribution and/or modification
   under the project’s base license version, or any later version per
   `Free Software Foundation recommendations <http://www.gnu.org/licenses/gpl-faq.html#VersionThreeOrLater>`__.


Copyright
~~~~~~~~~

-  Copyright for a particular Flux project SHALL be held jointly by
   the contributors to that project.

-  Flux projects SHALL NOT require a legal document such as a
   contributor license agreement or copyright assignment document
   to be signed by contributors.

-  Copyright for each source code module MAY be held by its authors.

-  All source code contributed to a Flux project SHALL include a copyright
   notice that declares the copyright holders and the license under which
   the source code may be copied, for example:

::

   /* Copyright 2014 Lawrence Livermore National Security, LLC
    * (c.f. AUTHORS, NOTICE.LLNS, COPYING)
    *
    * This file is part of the Flux resource manager framework.
    * For details, see https://github.com/flux-framework.
    *
    * SPDX-License-Identifier: LGPL-3.0
    */

-  The SPDX license shorthand is RECOMMENDED [#f2]_.

.. [#f1] `The Free-Libre / Open Source Software (FLOSS) License Slide <https://dwheeler.com/essays/floss-license-slide.html>`__, David A. Wheeler.

.. [#f2] `The Software Package Data Exchange (SPDX) <https://spdx.org/>`__.
