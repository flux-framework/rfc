.. github display
    GitHub is NOT the preferred viewer for this file. Please visit
    https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_48.html

48/Flux Framework Project Governance
####################################

This document describes the rules for the development and community management of the Flux Framework project.

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
- :doc:`spec_3`
- :doc:`spec_7`
- :doc:`spec_47`

Goals
*****

The goal of this governance document is to clearly define the roles, responsibilities, and decision-making mechanisms for the Flux Framework project to ensure consistent, transparent, and sustainable development.

Design
******

Project Governance
==================

The development and community management of the project will follow the governance rules described in this document.

Project Maintainers
-------------------

Project maintainers have admin access to the GitHub repository. The team of project maintainers is the following:

* `Tom Scogland <scogland1@llnl.gov>`_
* `Mark Grondona <grondona1@llnl.gov>`_
* `Jim Garlick <garlick1@llnl.gov>`_

1. Roles
--------

This project includes the following roles.

1.1. Maintainer
^^^^^^^^^^^^^^^
**Maintainers** are responsible for organizing activities around developing, maintaining, and updating the Project. Project maintainers will review and merge pull requests.

1.2. Collaborator
^^^^^^^^^^^^^^^^^
Any member willing to participate in the development of the project will be considered as a **collaborator**. Collaborators may propose changes to the project's source code. The mechanism to propose such a change is a GitHub pull request. A collaborator proposing a pull request is considered a **contributor**.

2. Development Workflow
-----------------------

The project adheres to a modern development philosophy centered on open standards and consistency.

* **Development Approach**: Modern development workflow centered on **test-driven development**, open standards, and consistent release cycles.
* **Release Cadence**: Releases are targeted monthly, coordinated with the **TOSS** (Tri-Lab Operating System Stack) operating system update schedule.
* **Versioning**: Components use **Semantic Versioning** for tagged releases on GitHub.
* **Continuous Integration/Delivery**: Comprehensive **CI/CD** is enforced across all repositories using **GitHub Actions**.
* **Testing**:
    * **Unit testing** is standard practice.
    * **Integration tests** are implemented using **sharness**.
    * **End-to-End (E2E) tests** are conducted using **Kind/Minikube**.

3. Distribution Channels
------------------------

Flux Framework components are available via multiple channels to support diverse HPC, cloud, and developer environments.

* **HPC/Source**: **Source tarballs** and **Spack packages** (``spack install flux-core``).
* **Containers/Cloud**:
    * Projects include dedicated **Developer container environments**.
    * Component containers are released alongside source code.
    * The **flux-operator** is distributed via YAML files and Container Images, and **Helm Charts** for Cloud/Kubernetes deployments.
* **Language Ecosystems**: **Python (pypi)** packages are distributed for Flux Python bindings.
* **Package Managers (In Progress)**: Efforts are underway to provide **rpms** and **debian packages**.

4. Governance & Standards
-------------------------

4.1. RFC Process
^^^^^^^^^^^^^^^^
Major architectural changes and protocol definitions must follow the Flux **Request for Comments (RFC) process**, fostering a "spec-first" philosophy.

4.2. Decision Making
^^^^^^^^^^^^^^^^^^^^
The project uses a **lazy consensus model** for most changes and standard issue resolutions.

4.3. Maintainer Review
^^^^^^^^^^^^^^^^^^^^^^
**Maintainer review is required** for all Pull Requests prior to merging.

5. Issue Governance
-------------------

5.1.
^^^^
Both collaborators and project maintainers may propose issues. The participation in the issue discussion is open and must follow the `Code of Conduct <spec_47>`_.

5.2.
^^^^
The group of project maintainers will be responsible for assigning labels to issues, as well as assign the issue to a project maintainer or contributor.

5.3.
^^^^
The group of project maintainers commit to give an answer to any issue in a period of time of **48 hours**.

6. Pull Request Governance
--------------------------

6.1.
^^^^
Both collaborators and project maintainers may propose pull requests. When a collaborator proposes a pull request, is considered contributor.

6.2.
^^^^
Pull requests should comply with the template provided. The assignment of labels and assignees to the pull request is the responsibility of the project maintainers.

6.3.
^^^^
The group of project maintainers commit to give an answer to any pull request in a period of time of **48 hours**.

6.4.
^^^^
The decision of accepting (or rejecting) a pull request will be taken by the group of project maintainers. The decision will be based on the following criteria:

* Two project maintainers must approve a pull request before the pull request can be merged.
* One project maintainer approval is enough if the pull request has been open for more than **14 days**.
* Approving a pull request indicates that the contributor accepts responsibility for the change.
* If a project maintainer opposes a pull request, the pull request cannot be merged (i.e., *veto* behavior). Often, discussions or further changes result in collaborators removing their opposition.
