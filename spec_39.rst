.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_39.html

##########################
39/Flux Security Signature
##########################

The Flux Security Signature is a NUL terminated string that represents
content secured with a digital signature.

- Name: github.com/flux-framework/rfc/spec_39.rst

- Editor: Jim Garlick <garlick@llnl.gov>

- State: raw

********
Language
********

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <https://tools.ietf.org/html/rfc2119>`__.

*****************
Related Standards
*****************

- :doc:`14/Canonical Job Specification <spec_14>`

- :doc:`15/Independent Minister of Privilege for Flux: The Security IMP <spec_15>`

- :doc:`38/Flux Security Key Value Encoding <spec_38>`

**********
Background
**********

The Flux Security IMP is the privileged component of Flux responsible for
launching tasks in a multi-user Flux installation.  Each job request is
signed by the submitting user and verified by the IMP as a precondition for
performing the user transition and starting tasks.  Signing deters tampering
when the job passes through the unprivileged Flux instance.  This is the
primary use case for the Flux Security Signature.

A job request is expressed as *jobspec* (RFC 14).  Importantly, jobspec
contains the proposed command line to run as well as the current working
directory and environment.  Signing the jobspec ensures that these parameters
are passed to the IMP exactly as specified by the user.

RFC 15 refers to the signed jobspec as *J*.  The content of *J* is thus fully
specified by this document and RFC 14.

*****
Goals
*****

- The signature mechanism SHOULD be configurable so that a site's existing
  security infrastructure can be used, if applicable.

- The signature payload MUST accommodate the maximum size of a serialized
  RFC 14 jobspec.

- The signature MUST be a UTF-8 string that does not contain NUL characters.

- The signature SHOULD support a configurable time-to-live.

**************
Implementation
**************

The Flux Security Signature is structured like the JSON Web Signature
Compact Serialization of `RFC 7515 <https://tools.ietf.org/html/rfc7515>`__.
It SHALL contain three components concatenated with period (``.``) delimiters:

HEADER.PAYLOAD.SIGNATURE

- The *header* SHALL be formatted using Flux Security Key Value Encoding
  (RFC 38), then base64 encoded.  The REQUIRED keys are listed below.
  The header is not encrypted.

- The *payload* is an arbitrary sequence of zero or more bytes that
  SHALL be base64 encoded.  The payload is not encrypted.

- The *signature* SHALL be a mechanism-dependent UTF-8 string that represents
  a signature over the other two components including the delimiter.
  The signature string SHALL NOT contain the NUL or period (``.``) characters.

The header and payload SHALL be encoded in the
`RFC 4648 <https://tools.ietf.org/html/rfc4648>`__ standard variant of base64.

The header SHALL contain the following keys:

version (integer)
  The Flux Security Signature version (currently must be set to 1).

mechanism (string)
  The mechanism used to create signature component.

userid (integer)
  The claimed userid.

Mechanism-specific keys MAY also be included in the header.

**********
Mechanisms
**********

Signing mechanisms include:

MUNGE
=====

The *munge* mechanism uses the `MUNGE <https://github.com/dun/munge/wiki>`__,
authentication service, which is simple to set up, and is often already
present on HPC clusters.

The header *mechanism* key SHALL be set to the string ``munge``.  No
mechanism-specific header keys are required.

Signing SHALL consist of the following steps:

#. Compute the 32 byte SHA-256 hash digest over HEADER.PAYLOAD

#. Construct a 33 byte MUNGE payload by concatenating a single byte *hash type*
   field of ``0x01`` (indicating SHA-256) and the hash digest computed above.

#. Encode the payload with ``munge_encode(3)`` to obtain the MUNGE credential
   which becomes the signature component.

.. note::
  MUNGE credentials conform to the signature component requirement of being a
  UTF-8 string without embedded NUL characters or periods.  See also: MUNGE
  `Credential Format <https://github.com/dun/munge/wiki/Credential-Format>`__.

Verification SHALL consist of the following steps:

#. Decode the MUNGE credential with ``munge_decode(3)`` to obtain the MUNGE
   payload and the MUNGE-authenticated userid.  Return values of EMUNGE_SUCCESS,
   EMUNGE_CRED_REPLAYED, or EMUNGE_CRED_EXPIRED SHALL be treated as success.

#. Re-compute the 32 byte SHA-256 hash digest over HEADER.PAYLOAD

#. Check that the MUNGE payload consists of 33 bytes: a single byte *hash type*
   field of ``0x01`` followed by the same 32 byte SHA-256 hash digest computed
   above.

#. Check that the MUNGE-authenticated userid matches the header *userid* field.

#. Call ``munge_ctx_get(3)`` on MUNGE_OPT_ENCODE_TIME to obtain the wall clock
   time that the credential was encoded.

#. Check that the time elapsed since the credential was encoded does not
   exceed the configured site time-to-live.

.. note::
  MUNGE imposes a short time-to-live on its credentials, but since
  Flux job requests may be pending for *days*, expired credential errors
  from MUNGE are ignored and a site configured time-to-live is imposed instead.
  Similarly, MUNGE detects replay attacks by only allowing a credential to be
  decoded once per host, but since Flux job requests may need to be verified
  by multiple parties on the same node, replay errors from MUNGE are ignored.

NONE
====

The *none* mechanism is useful for testing and for situations where the
signature format is needed for consistency but the veracity of the signature
is not important, such as in a single-user Flux instance.

The header *mechanism* key SHALL be set to the string ``none``.  No
mechanism-specific keys are required.  The *none* mechanism does not support
a time-to-live.

Signing SHALL consist of the following steps:

#. Set the signature component to the string ``none``.

Verification SHALL consist of the following steps:

#. Check that the signature component is the string ``none``.

#. Check that the real user id matches the header userid.

.. note::
  Requiring that the header userid matches the real user id deters use of
  the *none* mechanism in inappropriate situations, e.g. as a precondition
  to performing a user transition in the IMP.

.. note::
  As a reminder, the payload and header components are simply base64 encoded
  and may be read or written in a mechanism independent manner.
