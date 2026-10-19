# Security policy

## Reporting a vulnerability

Please report a suspected vulnerability privately, through GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
on the affected repository. Do not open a public issue for it.

Include: what an attacker can do, what they need in order to do it, and the
smallest reproduction you have. A codec-level issue is often a statement
about a peer that behaves badly, so the peer's behaviour matters as much as
the victim's.

## What is in scope

The codec's security properties are its own, and they are worth stating
because an implementation inherits them:

- **The codec carries no identity.** It says what the bytes are; it does not
  say who sent them. A deployment that puts an unauthenticated sender on a
  path has made a deployment's mistake, and the codec's updates will carry
  whatever that sender sends.
- **The codec is not confidential.** Its updates are readable by anyone on
  the path. Confidentiality and integrity are the deployment's to provide,
  and a deployment that needs them MUST provide them — a codec that assumes
  the link is trustworthy is a codec that carries an attacker's content into
  a receiver's surface.
- **A peer that misbehaves is contained by the codec, not trusted.** The
  caps (§7), the validation order (§6.1), the bounded decompression (§4.1)
  and the atomic application (§6.3) exist so that a hostile or broken peer
  cannot make a receiver allocate without bound, apply an update it did not
  validate, or hold a half-applied surface.
- **A peer cannot make the receiver believe the surface is correct.** The
  receiver's surface is exactly what the sender's updates said, and nothing
  more. A receiver that cannot advance reports it (§6.4) rather than
  guessing.
- **A peer can make the link slow.** That is the transport's business, and
  the codec's answer is the same: the receiver holds a coherent surface
  whether or not the next update arrives.

## What is out of scope

- The deployment's authentication, authorization, key management, and
  network configuration.
- Denial of service by a peer that a deployment has already authorized to
  connect and that simply sends a lot: the codec bounds what a peer can make
  the receiver *hold*, not how much bandwidth it may consume.
- What the content depicts. The codec moves cells; it does not know what
  they are.

## Supported versions

Only the current version of the codec is supported. A deployment that must
interoperate with an older one is carrying a second implementation of the
codec, which this codec does not permit.
