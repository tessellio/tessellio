# 4. The op stream

## 4.1 The envelope of a region

A region's `payload` is a **raw DEFLATE stream** (RFC 1951: no zlib header,
no gzip trailer). The decompressed bytes are the op stream.

A sender emits stored (`BTYPE=00`) blocks when the deflate level is 0, and
any valid DEFLATE stream otherwise. Both are acceptable: the choice is a
sender-side cost-and-ratio decision, not a format variant.

A receiver decompresses **bounded**: it aborts as soon as the output would
exceed `MAX_REGION_OPS_BYTES` (§7), and it never allocates a buffer larger
than the cap.

## 4.2 The grammar

The op stream is a little-endian sequence of ops. A region's ops address the
region's own coordinate space, with `(0,0)` at its top-left.

| op | byte | operands | semantics |
|---|---|---|---|
| `END` | `0x00` | — | end of the op stream; MUST be the last byte consumed. Any trailing byte after the first `END` is an error |
| `ROW` | `0x01` | `row: u16` | set the current row. The current row is undefined until the region's first `ROW`; a writing op before any `ROW`, a first `ROW` with `row >= height`, or a later `ROW` that is not strictly greater than the previous one is an error |
| `SPAN` | `0x02` | `x: u16`, `len: u16`, then `len` × `u16le` cell values | write `len` literal cells at columns `x..x+len` on the current row |
| `FILL` | `0x03` | `x: u16`, `len: u16`, `value: u16le` | write `len` copies of `value` at columns `x..x+len` on the current row |

The cell values are at the wire fidelity of §2.2: one unsigned 16-bit value
per cell.

Padding between ops is not allowed. A region that is just `END` is valid and
paints nothing.

## 4.3 The per-region rules

A receiver enforces these rules on every region, and any violation rejects
the region — and with it the whole update:

1. `len >= 1`; `x + len <= width`. `x` and `len` are unsigned 16-bit, so a
   row run never needs splitting (the width is at most 8192).
2. Ops are in strictly increasing row order, and within a row in strictly
   ascending, non-overlapping `x` order: `x >= previous_x + previous_len`,
   with one `ROW` per row the region writes.
3. The stream ends with `END`.
4. The decompressed length does not exceed `MAX_REGION_OPS_BYTES`, and the
   compressed length does not exceed `MAX_REGION_WIRE_BYTES`.

## 4.4 Coverage

The coverage rule depends on what the update is:

- For a **self-contained** update (`base_update_id == 0`), every region MUST
  be *fully covered*: within each row, coverage is contiguous from column 0
  to column `width-1`, and every row `0..height-1` is written exactly once
  by a `ROW` op in ascending order. A region that leaves a row partly
  written, or writes a row twice, is rejected.
- For a **chained** update, coverage is sparse: rules 1–3 of §4.3 only. The
  cells a region does not write keep the values they had.

The coverage rule is what makes a self-contained update usable: a receiver
that applies one holds exactly the surface the sender had, whatever it held
before.

## 4.5 The op budget

The sender's choice of ops is not constrained by the format — a sender may
write a row as `SPAN`s, as a `FILL`, or as any mixture — but the reference
implementation's choices are the ones the corpus records:

- a constant run of at least `FILL_MIN_RUN` cells (8) is written as a
  `FILL`; a shorter one stays literal;
- a row's cells are written in ascending column order, without gaps, except
  where the region's coverage is sparse.

A sender that chooses differently produces a different byte string for the
same content. The format does not forbid it; the corpus pins the reference
implementation's choice, because the corpus is that implementation's
evidence.
