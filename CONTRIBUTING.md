# Contributing to the specification

A change to this specification is a change to a contract between
implementations that do not share an author. It is therefore reviewed like
code, and it carries the same obligations.

## Before you propose

1. **Read the whole section** the change touches, and the sections it
   depends on. Most of the codec's rules are stated once and referenced
   everywhere; a change that contradicts one of them is a change to all of
   them.
2. **Check the limits** (§7) and the invariants (§5.3). A change that breaks
   an invariant is not a change to the specification — it is a change to what
   the codec promises.
3. **Look for the rule in the reference implementation.** The implementation
   is normative too, and where the two disagree, one of them is a bug. A
   proposal that says "the specification should say what the code does" is a
   legitimate proposal, but it must say which side is wrong and why.

## The shape of a proposal

Describe the **observable behaviour**, not the wording:

- what a receiver does, in terms another implementation can check;
- what a sender may rely on;
- what changes for an existing implementation, and how it migrates.

A proposal that only rewrites a paragraph is a proposal to change how the
document reads, which is a different thing and is reviewed as one.

## What a change must include

- The specification, updated.
- The reference implementation, updated, if the change is observable.
- The conformance corpus, regenerated, if the change alters a decision the
  corpus records. The corpus is **generated, never written by hand**: run
  the gate with `--update` and commit the result. The diff of the corpus is
  part of the change's review, and it is the clearest evidence of what the
  change actually does.
- The cross-references, still resolving. Run the checker.

## Changing a version

The codec accepts exactly one version. A change that is not backward
compatible is a new version, and it means:

- the version's wire id changes;
- every implementation changes with it;
- the deployment ships every artifact in one window.

There is no transition window, no dual acceptor, and no downgrade. That is a
deliberate cost: a codec with two versions in the field is a codec with two
behaviours, and the ambiguity is paid for by every user of it.

## Style

- The codec speaks about **senders** and **receivers** — not about hosts,
  viewers, gateways and relays. The roles are what the codec defines; where
  they sit is the deployment's.
- The codec's unit of media state is an **update**, its parts are **parts**,
  and its content is a **surface** of **cells**. A word that belongs to a
  transport does not belong here.
- Requirements are written in capitals and are testable. A sentence that
  cannot be checked is a sentence that cannot be wrong, and therefore cannot
  be right either.
- Numbers are normative. If a number appears in prose, it is a claim about a
  number that appears in the table of §7, and the two must agree.

## The checkers

| Checker | What it enforces |
|---|---|
| `scripts/check-references.mjs` | every cross-reference resolves to a section that exists |
| the conformance gate | the corpus's shape, and that the corpus is reproducible |

Run both before opening a proposal.
