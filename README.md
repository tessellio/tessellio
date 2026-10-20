# Tessellio

The specification of the **Tessellio** screen codec.

Tessellio moves a changing surface over a link that loses, reorders, or
delays. It paints a surface as tiles of cells and moves only the tiles that
changed; an update is either self-contained (it establishes the whole
surface) or chained (it continues exactly the surface the named base
established).

- **[The specification](spec/00-index.md)** — the normative document.
- **[`tessellio-core`](https://github.com/tessellio/tessellio-core)** — the
  Rust reference implementation.
- **[`tessellio-ts`](https://github.com/tessellio/tessellio-ts)** — the
  browser-side reference implementation.
- **[`tessellio-proto`](https://github.com/tessellio/tessellio-proto)** — the
  update envelope's wire schema.
- **[`tessellio-conformance`](https://github.com/tessellio/tessellio-conformance)**
  — the corpus and the gate that keeps it honest.

## What the codec is

A codec is a contract between implementations that do not share an author.
The specification therefore says what the bytes are, what a receiver must do
with them, and what a sender may assume — and nothing else. It does not
describe a product, a deployment, a vendor, or a particular application.

The codec is not a transport: it does not frame, address, retransmit,
reorder, pace, measure, or acknowledge anything. A transport moves the
codec's updates as opaque bytes, and the codec never sees the transport's
framing.

## The one property everything rests on

Change detection compares the same 16-bit cells the receiver's surface
holds, and the sender's reference advances only over the cells an update
actually carried. So at every instant the receiver's surface equals the
sender's reference, cell for cell — and one lost update heals, because the
sender can roll its reference back and re-encode the difference.

That property is §5.3 of the specification, and it is what the reference
implementation's self-check verifies after every update it builds.

## Reading the specification

| | |
|---|---|
| [1. Vocabulary](spec/01-vocabulary.md) | what the codec calls things |
| [2. Content](spec/02-content.md) | the surface, the cell, the capture representation |
| [3. The update envelope](spec/03-envelope.md) | the identity of an update, and its parts |
| [4. The op stream](spec/04-op-stream.md) | the grammar a region's payload carries |
| [5. The encoder](spec/05-encoder.md) | what a sender compares, and what it advances |
| [6. The decoder](spec/06-decoder.md) | what a receiver accepts, and in what order |
| [7. Limits](spec/07-limits.md) | the constant table every implementation enforces |
| [8. Conformance](spec/08-conformance.md) | the vectors, the corpus, and the gate |
| [9. Annexes](spec/09-annexes.md) | the vectors' bytes, the measured bounds, the errors |

## Verifying it

The codec has no continuous integration: its checks are local.

```bash
scripts/verify.sh                # check what is present
scripts/verify.sh --all          # require every repository
```

The repositories are expected next to this one as `../tessellio-core`,
`../tessellio-ts`, `../tessellio-proto` and `../tessellio-conformance`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). A change to the specification is a
change to a contract between implementations that do not share an author, and
it is reviewed like code.

## Status

In development. One moving version, `v0.1.0`, naming the current commit:
there is exactly one tag, and a change moves it.

## Licence

PolyForm Noncommercial License 1.0.0. See [LICENSE](LICENSE).
