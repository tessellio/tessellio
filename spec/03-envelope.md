# 3. The update envelope

## 3.1 An update is a whole, identified object

An update is either **self-contained** or **chained**:

- A **self-contained** update carries `base_update_id = 0`. It is
  self-contained, its geometry is authoritative, and any receiver can apply
  it whatever it currently holds. Its regions must be *fully covered* (§4.4).
- A **chained** update carries `base_update_id > 0`: the `update_id` of the
  update it continues. A receiver applies it only onto exactly that state,
  and a receiver that does not hold that state refuses the update and says
  so (§6.2).

An update is applied atomically: every part of it, or none of it. A receiver
that has applied part 0 of 3 and then lost part 1 holds nothing of that
update.

## 3.2 The envelope

The update travels as an ordinary message. The envelope is the codec's
schema:

| field | type | tag | semantics |
|---|---|---|---|
| `update_id` | `int64` | 1 | ≥ 1; monotone within one sender; every part of an update carries the same value |
| `base_update_id` | `int64` | 2 | `0` ⇒ self-contained; otherwise the `update_id` the update continues |
| `width` | `int32` | 3 | surface width, `1..=8192`, with `width * height <= 16_777_216` |
| `height` | `int32` | 4 | surface height, same bounds |
| `part_index` | `int32` | 5 | `0..part_count-1`; the parts of an update arrive in ascending index order on one ordered stream |
| `part_count` | `int32` | 6 | `1..=8`; replicated in every part |
| `update_bytes` | `int64` | 7 | the sum of the region payload bytes over the **whole** update; replicated in every part |
| `codec` | `Codec` | 8 | must be `8` (`CODEC_TESSELLIO`) or the receiver rejects the update |
| `regions` | `repeated Region` | 9 | this part's regions, ascending by `(y, x)`, byte-disjoint from the regions of the other parts |

`Region`:

| field | type | tag |
|---|---|---|
| `x` | `int32` | 1 |
| `y` | `int32` | 2 |
| `width` | `int32` | 3 |
| `height` | `int32` | 4 |
| `payload` | `bytes` | 5 |

The envelope is deliberately thin. It carries the identity of the update, the
part it is, and the rectangles it paints; everything else — the grammar of a
payload, the rules a payload obeys — is in §4.

The canonical encoding is what the schema's encoder produces: fields equal
to their default (`0`) are omitted, every other field is emitted, and the
regions are emitted in order. The committed vectors (§8) depend on this:
each one re-encodes to exactly the documented bytes.

## 3.3 The parts

Every part of an update repeats the update's identity (`update_id`,
`base_update_id`, `width`, `height`, `part_count`, `update_bytes`), so a
hop or a receiver never has to guess how many parts an update has or whether
it is complete.

The parts of update `U` arrive as `part_index` `0, 1, …, part_count-1`. A
different `update_id` before completion discards the partial update; a first
part that is not index 0 refuses the update; the parts of one update must
agree on `part_count`, `update_bytes`, `base_update_id`, and geometry; and
the sum of every part's region payload bytes must equal `update_bytes`.

A receiver MUST apply an update only when every part has arrived and every
part has been validated. A receiver MUST NOT apply a part on its own.

## 3.4 The monotonicity of the identifiers

`update_id` is monotone within one sender. It is the sender's own counter,
and it is the only ordering the codec knows: a receiver compares an
update's `base_update_id` against the identifier of the update it has
applied, and nothing else.

A sender that restarts begins a new identifier space. A receiver that sees
an identifier it has already applied is looking at a sender's restart, and
it MUST treat the update as self-contained rather than applying it onto a
state it no longer holds.

Identifiers are scoped to one sender. Two senders may use the same
identifier space without any consequence: an update is always applied to
the surface of the receiver that received it.
