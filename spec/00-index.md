# The Tessellio screen codec (v1)

Status: normative. This document is the specification of **Tessellio**: the
wire format of a codec that moves a changing surface over a link that loses,
reorders, or delays.

The codec has one operator-facing name, **Tessellio**, and one wire id,
**8**. There is no second payload format, no negotiation, and no fallback:
an update whose codec field is not 8 is rejected whole.

## What this document is

A codec is a contract between implementations that do not share an author. It
therefore says what the bytes are, what a receiver must do with them, and
what a sender may assume — and nothing else. It does not describe a
product, a deployment, a vendor, or a particular application.

Concretely, the document does **not** say:

- how the content was produced, or what it depicts;
- who sends it, or over what transport it travels — a transport moves the
  codec's updates as opaque bytes, and the codec never sees the transport's
  framing, its congestion control, or its acknowledgements;
- how a session is authenticated, or who may open one;
- what the receiver does with the surface once it has painted it.

It **does** say:

- the byte layout of every part, and the validation order;
- the op grammar, and the rules a decoder enforces on it;
- the limits every implementation enforces, in one table;
- the encoder's contract: what it compares, what it advances, and what it
  promises the receiver;
- the decoder's contract: what it accepts, in what order, and what it must
  never do;
- the invariants an implementation must preserve.

## The reference implementations

| | |
|---|---|
| [`tessellio-core`](https://github.com/tessellio/tessellio-core) | Rust, sans-IO: the normative implementation of the byte format and every policy |
| [`tessellio-ts`](https://github.com/tessellio/tessellio-ts) | TypeScript: the browser-side mirror |
| [`tessellio-proto`](https://github.com/tessellio/tessellio-proto) | the update envelope's wire schema |
| [`tessellio-conformance`](https://github.com/tessellio/tessellio-conformance) | the corpus and the gate that keeps it honest |

When this document and the reference implementation disagree, that is a bug
in one of them. The implementation is normative too: where the two differ,
the one that is wrong must say why.

## The table of contents

| | |
|---|---|
| [1. Vocabulary](01-vocabulary.md) | what the codec calls things |
| [2. Content](02-content.md) | the surface, the cell, the capture representation |
| [3. The update envelope](03-envelope.md) | the identity of an update, and its parts |
| [4. The op stream](04-op-stream.md) | the grammar a region's payload carries |
| [5. The encoder](05-encoder.md) | what a sender compares, and what it advances |
| [6. The decoder](06-decoder.md) | what a receiver accepts, and in what order |
| [7. Limits](07-limits.md) | the constant table every implementation enforces |
| [8. Conformance](08-conformance.md) | the vectors, the corpus, and the gate |
| [9. Annexes](09-annexes.md) | the vectors' bytes, the measured bounds, the errors |

## How to read this document

Requirements are written in capitals and are testable. A sentence that
cannot be checked is a sentence that cannot be wrong, and therefore cannot
be right either.

Numbers are normative. If a number appears in prose, it is a claim about a
number that appears in the table of §7, and the two must agree.

A cross-reference of the form `§N.N` names a section of this document.
Every cross-reference resolves; `scripts/check-references.mjs` fails the
build otherwise.
