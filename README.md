RFC Index
=========

This is the Flux RFC project.

We collect specifications for APIs, file formats, wire protocols, and
processes.

The full RFC specs can be found on [readthedocs](https://flux-framework.readthedocs.io/projects/flux-rfc/en/latest).
Details about each of the active RFC documents can be found [in the index](index.rst)

Table of Contents
-----------------

- [1/C4.1 - Collective Code Construction Contract](spec_1.rst)
- [2/Flux Licensing and Collaboration Guidelines](spec_2.rst)
- [3/Flux Message Protocol](spec_3.rst)
- [4/Flux Resource Model](spec_4.rst)
- [5/Flux Broker Modules](spec_5.rst)
- [6/Flux Remote Procedure Call Protocol](spec_6.rst)
- [7/Flux Coding Style Guide](spec_7.rst)
- [9/Distributed Communication and Synchronization Best Practices](spec_9.rst)
- [10/Content Storage](spec_10.rst)
- [11/Key Value Store Tree Object Format v1](spec_11.rst)
- [12/Flux Security Architecture](spec_12.rst)
- [13/Simple Process Manager Interface v1](spec_13.rst)
- [14/Canonical Job Specification](spec_14.rst)
- [15/Independent Minister of Privilege for Flux: The Security IMP](spec_15.rst)
- [16/KVS Job Schema](spec_16.rst)
- [18/KVS Event Log Format](spec_18.rst)
- [19/Flux Locally Unique ID (FLUID)](spec_19.rst)
- [20/Resource Set Specification](spec_20.rst)
- [21/Job States and Events](spec_21.rst)
- [22/Idset String Representation](spec_22.rst)
- [23/Flux Standard Duration](spec_23.rst)
- [24/Flux Job Standard I/O Version 1](spec_24.rst)
- [25/Job Specification Version 1](spec_25.rst)
- [26/Job Dependency Specification](spec_26.rst)
- [27/Flux Resource Allocation Protocol Version 1](spec_27.rst)
- [28/Flux Resource Acquisition Protocol Version 1](spec_28.rst)
- [29/Hostlist Format](spec_29.rst)
- [30/Job Urgency](spec_30.rst)
- [31/Job Constraints Specification](spec_31.rst)
- [32/Flux Job Execution Protocol Version 1](spec_32.rst)
- [33/Flux Job Queues](spec_33.rst)
- [34/Flux Task Map](spec_34.rst)
- [35/Constraint Query Syntax](spec_35.rst)
- [36/Batch Script Directives](spec_36.rst)
- [37/File Archive Format](spec_37.rst)
- [38/Flux Security Key Value Encoding](spec_38.rst)
- [39/Flux Security Signature](spec_39.rst)
- [40/Fluxion Resource Set Extension](spec_40.rst)
- [41/Job Information Service](spec_41.rst)
- [42/Subprocess Server Protocol](spec_42.rst)
- [43/Job List Service](spec_43.rst)
- [44/Flux Library for Adaptable Notifications](spec_44.rst)

Build Instructions
------------------

To build with python virtual environments:

```bash
virtualenv -p python3 sphinx-rtd
source sphinx-rtd/bin/activate
git clone git@github.com:flux-framework/rfc
cd rfc
pip install -r requirements.txt
make html
```


Change Process
--------------

The change process is [C4.1](spec_1.rst) with
a few modifications:

-   A specification is created and modified by pull requests according
    to C4.1.
-   Each specification has an editor who publishes the RFC to (website
    TBD) as needed.
-   Each specification has a status on that website: Raw, Draft, Stable,
    Legacy, Retired, Deleted.
-   Non-cosmetic changes are allowed only on Raw and Draft
    specifications.
