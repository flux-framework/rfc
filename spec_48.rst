.. github display
    GitHub is NOT the preferred viewer for this file. Please visit
    https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_48.html

48/Flux Framework Project Governance
####################################

This document describes the governance model for the Flux Framework project, outlining the principles, roles, and procedures that guide its development and community management.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_48.rst
  * - **Forked from**
    - https://github.com/jlcanovas/gh-best-practices-template
  * - **Editor**
    - Vanessa Sochat <sochat1@llnl.gov>
  * - **State**
    - draft

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_1`
- :doc:`spec_2`
- :doc:`spec_7`
- :doc:`spec_47`

Goals
*****

The goal of this governance document is to clearly define the roles, responsibilities, and decision-making mechanisms for the Flux Framework project to ensure consistent, transparent, and sustainable development.

Project Governance
******************

The development and community management of the project will follow the governance rules described in this document.

Project Maintainers
===================

Project maintainers have admin access to the GitHub repository. Maintainers vary by GitHub project, and are viewable in the ``CODEOWNERS`` file provided in each respective project.

Roles
=====

This project includes the roles of **Maintainer** and **Contributor,** each of which is defined under `RFC 1 <https://flux-framework.readthedocs.io/projects/flux-rfc/en/latest/spec_1.html#preliminaries>`_. 

Development Workflow
====================

The project adheres to a modern development philosophy centered on open standards and consistency. See details in `RFC 1 "Development Process" <https://flux-framework.readthedocs.io/projects/flux-rfc/en/latest/spec_1.html#development-process>`_.

Governance & Standards
======================

RFC Process
^^^^^^^^^^^

See the `Evolution of Public Contracts <https://flux-framework.readthedocs.io/projects/flux-rfc/en/latest/spec_1.html#evolution-of-public-contracts>`_ section of RFC 1. 

Decision Making
^^^^^^^^^^^^^^^
The project uses a `lazy consensus model <https://openoffice.apache.org/docs/governance/lazyConsensus.html>`_ for most changes and standard issue resolutions.

Maintainer Review
^^^^^^^^^^^^^^^^^
**Maintainer review is required** for all Pull Requests prior to merging.

Issue Governance
----------------

* Both collaborators and project maintainers may propose issues. The participation in the issue discussion is open and must follow the `Code of Conduct <spec_47>`_.
* The group of project maintainers will be responsible for assigning labels to issues, as well as for assigning the issue to a project maintainer or contributor. The `merge-when-passing` label MAY be applied by a maintainer to allow a pull request to be automatically merged once it has met all requirements.
* The group of project maintainers SHOULD commit to responding to any issue within **72 hours** of the issue's creation.

Pull Request Governance
-----------------------

* Both collaborators and project maintainers may propose pull requests.
* Pull requests SHOULD describe the contribution. The assignment of labels and assignees to the pull request is the responsibility of the project maintainers.
* The group of project maintainers SHOULD provide feedback to any pull request within **72 hours** of the pull request's creation.
* The decision of accepting (or rejecting) a pull request will be taken by the group of project maintainers. The criteria and process for making the decision is described in `RFC 1 "Development Process" <https://flux-framework.readthedocs.io/projects/flux-rfc/en/latest/spec_1.html#development-process>`_.
