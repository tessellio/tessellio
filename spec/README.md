# Tessellio

The specification of the **Tessellio** screen codec: a codec that moves a
changing surface over a link that loses, reorders, or delays.

Tessellio paints a surface as tiles of cells and moves only the tiles that
changed. An update is either self-contained — it establishes the whole
surface — or chained, continuing exactly the surface the named base
established.

## Reading it

Start with [00-index.md](00-index.md): it says what the document is, what
it deliberately does not cover, and the order to read the rest in.

| Section | What it settles |
|---|---|
| [1. Vocabulary](01-vocabulary.md) | the words, the two participants, and what the codec does not do |
| [2. Content](02-content.md) | the surface, the cell, the capture representation, the pointer |
| [3. The update envelope](03-envelope.md) | the identity of an update, its parts, and their assembly |
| [4. The op stream](04-op-stream.md) | the grammar a region's payload carries, and the coverage rule |
| [5. The encoder](05-encoder.md) | what a sender compares, what it advances, and what it promises |
| [6. The decoder](06-decoder.md) | what a receiver accepts, in what order, and what it reports |
| [7. Limits](07-limits.md) | the constant table every implementation enforces |
| [8. Conformance](08-conformance.md) | the vectors, the corpus, and the gate |
| [9. Annexes](09-annexes.md) | the vectors' bytes, the measured bounds, the errors |

## The reference implementations

| | |
|---|---|
| [`tessellio-core`](https://github.com/tessellio/tessellio-core) | Rust, sans-IO: the normative implementation |
| [`tessellio-ts`](https://github.com/tessellio/tessellio-ts) | TypeScript: the browser-side mirror |
| [`tessellio-proto`](https://github.com/tessellio/tessellio-proto) | the update envelope's wire schema |
| [`tessellio-conformance`](https://github.com/tessellio/tessellio-conformance) | the corpus and the gate that keeps it honest |

## Contributing to the specification

A change to this document is a change to a contract between
implementations that do not share an author, so it is reviewed like code:

1. Open an issue describing the problem, not the wording.
2. Propose the change with the observable behaviour it produces and the
   behaviour it replaces.
3. Update the reference implementation and the conformance corpus in the
   same change: a specification that no implementation follows is a wish.

A change that alters a decision the corpus records MUST regenerate the
corpus, and the diff is part of the review.

## Conventions

The key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT** and **MAY**
are to be interpreted as in RFC 2119 and RFC 8174.

A rule written as a numbered algorithm is normative, and so is the order
of its steps.

## Licence

PolyForm Noncommercial License 1.0.0. See [LICENSE](../LICENSE).
