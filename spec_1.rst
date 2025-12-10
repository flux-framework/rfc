.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_1.html

1/C4.1 - Collective Code Construction Contract
##############################################

The Collective Code Construction Contract (C4.1) is an evolution of the
github.com `Fork + Pull Model <https://docs.github.com/en/pull-requests/>`__,
aimed at providing an optimal collaboration model for free software
projects.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_1.rst
  * - **Forked from**
    - rfc.zeromq.org/spec:22/C4.1
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - draft

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_2`
- :doc:`spec_7`
- :doc:`spec_47`
- :doc:`spec_48`

Goals
*****

C4.1 is meant to provide a reusable optimal collaboration model for open source software projects. It has these specific goals:

-  To maximize the scale of the community around a project, by reducing the friction for new Contributors and creating a scaled participation model with strong positive feedbacks;

-  To relieve dependencies on key individuals by separating different skill sets so that there is a larger pool of competence in any required domain;

-  To allow the project to develop faster and more accurately, by increasing the diversity of the decision making process;

-  To support the natural life cycle of project versions from experimental through to stable, by allowing safe experimentation, rapid failure, and isolation of stable code;

-  To reduce the internal complexity of project repositories, thus making it easier for Contributors to participate and reducing the scope for error;

-  To enforce collective ownership of the project, which increases economic incentive to Contributors and reduces the risk of hijack by hostile entities.


Design
******

Preliminaries
=============

-  The project SHALL use the git distributed revision control system.

-  The project SHALL be hosted on github.com or equivalent, herein called the "Platform".

-  The project SHALL use the Platform issue tracker.

-  The project SHOULD have clearly documented guidelines for code style.

-  A "Contributor" is a person who wishes to provide a patch, being a set of commits that solve some clearly identified problem.

-  A "Maintainer" is a person who merge patches to the project. Maintainers are not developers; their job is to enforce process.

-  Contributors SHALL NOT have commit access to the repository unless they are also Maintainers.

-  Maintainers SHALL have commit access to the repository.

-  Everyone, without distinction or discrimination, SHALL have an equal right to become a Contributor under the terms of this contract.

Licensing and Ownership
=======================

-  The project SHALL use a share-alike license, such as the GPLv3 or a variant thereof (LGPL, AGPL), or the MPLv2 for reasons outlined in :doc:`RFC 2 <spec_2>`.

-  All contributions to the project source code ("patches") SHALL use the same license as the project.

-  All patches are owned by their authors. There SHALL NOT be any copyright assignment process.

-  The copyrights in the project SHALL be owned collectively by all its Contributors.

-  The git commit history SHALL be considered the primary source of contributor identities.

Patch Requirements
==================

-  Maintainers and Contributors MUST have a Platform account and SHOULD use their real names or a well-known alias.

-  A patch SHOULD be a minimal and accurate answer to exactly one identified and agreed problem.

-  A patch MUST adhere to the code style guidelines of the project defined in :doc:`RFC 7 <spec_7>`.

-  A patch MUST adhere to the "Evolution of Public Contracts" guidelines defined below.

-  A patch SHALL NOT include non-trivial code from other projects unless the Contributor is the original author of that code.

-  A patch MUST compile cleanly and pass project self-tests on at least the principle target platform.

-  A patch MUST be accompanied by a commit message.

-  A commit message MUST include a title summarizing the change. The title SHOULD be 50 characters or less.

-  A commit message MUST include a body. The body SHOULD include a blank line after the title.

-  A commit message SHOULD be written in the imperative (Fixes or Fix).

-  A commit message title MAY denote the section of code being changed with a tag followed by a single colon, e.g. ``name: short description``.

-  A commit message title SHOULD NOT include a period.

-  A commit message body SHOULD be wrapped at 72 characters, with the exception of non-prose lines like list items, quoted text, or quotes from other commits.

-  A commit message body SHOULD include a description of the change being made and its reason and/or purpose.

-  Where applicable, a commit message body SHOULD reference an Issue by number (e.g. Fixes #33").

-  A commit message body SHOULD begin with ``Problem:`` and a short paragraph describing the problem solved by the commit.  Even commits that add features MAY include such a problem statement.

-  A "Correct Patch" is one that satisfies the above requirements.

Development Process
===================

-  Change on the project SHALL be governed by the pattern of accurately identifying problems and applying minimal, accurate solutions to these problems.

-  To request changes, a user SHOULD log an issue on the project Platform issue tracker.

-  The user or Contributor SHOULD write the issue by describing the problem they face or observe.

-  The user or Contributor SHOULD seek consensus on the accuracy of their observation, and the value of solving the problem.

-  Users SHALL NOT log feature requests, ideas, suggestions, or any solutions to problems that are not explicitly documented and provable.

-  Thus, the release history of the project SHALL be a list of meaningful issues logged and solved.

-  To work on an issue, a Contributor SHALL fork the project repository and then work on their forked repository.

-  To submit a patch, a Contributor SHALL create a Platform pull request back to the project.

-  A Contributor SHALL NOT commit changes directly to the project.

-  If the Platform implements pull requests as issues, a Contributor MAY directly send a pull request without logging a separate issue.

-  To discuss a patch, people MAY comment on the Platform pull request, on the commit, or elsewhere.

-  To accept or reject a patch, a Maintainer SHALL use the Platform interface.

-  Maintainers SHOULD NOT merge their own patches except in exceptional cases.

-  Maintainers SHALL merge correct patches from other Contributors as described in :doc:`spec_48`.

-  The Contributor MAY tag an issue as "Ready" after making a pull request for the issue.

-  The user who created an issue SHOULD close the issue after checking the patch is successful.

-  Maintainers SHOULD ask for improvements to incorrect patches and SHOULD reject incorrect patches if the Contributor does not respond constructively.

-  Maintainers MAY commit changes to non-source documentation directly to the project.

-  Autotools products, if applicable, SHOULD NOT be checked into the project
   revision control system

Release Process
===============

-  Releases SHALL be tagged with git annotated tags.

-  Release names SHALL employ version numbers that follow the
   Semantic Versioning 2.0.0 standard, (C.f. https://semver.org).

-  Release materials for projects that use GNU Autotools SHOULD include
   "dist tarballs"; that is, a source distribution with pre-generated
   configure script, Makefile.in, etc..

Creating Stable Releases
========================

-  The project SHALL have one branch ("master") that always holds the latest in-progress version and SHOULD always build.

-  The project SHALL NOT use topic branches for any reason. Personal forks MAY use topic branches.

-  To make a stable release someone SHALL fork the repository by copying it and thus become maintainer of this repository.

-  Forking a project for stabilization MAY be done unilaterally and without agreement of project maintainers.

-  A stabilization project SHOULD be maintained by the same process as the main project.

-  A patch to a stabilization project declared "stable" SHALL be accompanied by a reproducible test case.

Evolution of Public Contracts
=============================

-  All Public Contracts (APIs or protocols) SHOULD be documented.

-  All Public Contracts SHOULD have space for extensibility and experimentation.

-  A patch that modifies a stable Public Contract SHOULD not break existing applications unless there is overriding consensus on the value of doing this.

-  A patch that introduces new features to a Public Contract SHOULD do so using new names.

-  Old names SHOULD be deprecated in a systematic fashion by marking new names as "experimental" until they are stable, then marking the old names as "deprecated".

-  When sufficient time has passed, old deprecated names SHOULD be marked "legacy" and eventually removed.

-  Old names SHALL NOT be reused by new features.

-  When old names are removed, their implementations MUST provoke an exception (assertion) if used by applications.

Further Reading
***************

-  `ZeroMQ - The Guide, Chapter 6: The ZeroMQ Community <https://zguide.zeromq.org/docs/chapter6/#the-community>`__

-  `Argyris' Models 1 and 2 <https://en.wikipedia.org/wiki/Chris_Argyris>`__ - the goals of C4.1 are consistent with Argyris' Model 2.

-  `Toyota Kata <https://en.wikipedia.org/wiki/Toyota_Kata>`__ - covering the Improvement Kata (fixing problems one at a time) and the Coaching Kata (helping others to learn the Improvement Kata).

Implementations
***************

-  The `ZeroMQ community <https://zeromq.org>`__ uses the C4.1 process for many projects.
