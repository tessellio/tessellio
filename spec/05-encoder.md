# 5. The encoder

The encoder is the stateful half of the codec. It holds a **reference** —
its copy of the surface it believes the receiver holds — and every update
it produces is built by comparing a capture against that reference.

## 5.1 The comparison

The sender MUST compare the capture at the **wire fidelity** of §2.2: the
capture's cells are reduced to 16-bit values, and those values are what is
compared. A cell that differs only in bits the wire does not carry is not a
change.

This is the rule the whole codec rests on. The reference holds 16-bit values,
the receiver's surface holds the expansion of 16-bit values, and the two are
equal by construction — so a cell that the comparison calls unchanged is
unchanged for the receiver too, and one it calls changed is changed in a way
the receiver can see.

## 5.2 What the reference advances

The sender's reference MUST advance **only over the cells an update actually
carries**. A cell the update did not write keeps the value the receiver
still holds, so the reference and the receiver's surface stay equal.

An encoder that advanced its reference over the whole capture would drift
away from the receiver within one update: the cells the update did not carry
were never sent, and the receiver still holds the old ones.

## 5.3 The invariant

> **INV-R.** After every update the sender has applied to its reference, the
> sender's reference equals the receiver's surface, cell for cell.

This is the property the encoder exists to maintain, and it is what the
encoder's own self-check verifies: after building an update, the sender
decodes it with the same decoder a receiver uses and compares the result
against its reference. A mismatch is a defect in the codec, and it is
reported through the telemetry hook (§5.8) rather than shipped.

## 5.4 The rectangle search

The cells that changed are grouped into rectangles. The reference
implementation's search is:

1. **Tiles.** The surface is divided into 64×64 tiles. A tile with no
   changed cell is discarded whole.
2. **Greedy rectangles.** The remaining tiles are merged into rectangles by
   a greedy sweep: for each row of the tile grid, the widest run of adjacent
   changed tiles is taken as a rectangle.
3. **Exact bounds.** Each rectangle is shrunk to the exact bounding box of
   the cells that changed inside it.
4. **Merge.** Rectangles that are adjacent and whose union is cheaper to
   send as one are merged.

The search is a sender-side decision. The format constrains the result, not
the method: a receiver accepts any set of regions that obeys §4.

## 5.5 The refresh budget

A change larger than the sender's budget is completed over consecutive
updates. The accepted update carries at most `DELTA_REFRESH_CELLS` cells
(131 072) of work, or `DELTA_OPS_BUDGET_BYTES` of ops, and the cells that
were not sent still differ from the reference — so the next update
re-detects them.

The progress guarantee (`DELTA_REFRESH_MIN_CELLS`, 4096) means an update
that carries anything carries at least that much work, so a stream cannot
stall behind the budget.

The budget is what keeps one update from exceeding the caps of §7. It is a
sender's decision, and a sender that never exceeds the caps needs no
budget.

## 5.6 The self-contained update

A self-contained update establishes the whole surface. The reference
implementation builds it in **bands** of `RESET_BAND_ROWS` rows (256),
each band encoded independently, so a wide surface is encoded in parallel
and split into at most `RESET_MAX_PARTS` parts.

A band whose payload would exceed the per-region cap is split further, until
it fits or cannot be split at all. A surface that cannot be encoded within
the caps is reported as an error, not truncated silently: a truncated
self-contained update violates the coverage rule of §4.4, and a receiver
would reject it.

A sender produces a self-contained update when it has no reference, when the
geometry changed, when a receiver asked for one, or when the journal cannot
reach the base a receiver reported.

## 5.7 The undo journal

The sender keeps a bounded **undo journal**: the writes it applied to its
reference, in reverse order, so it can roll the reference back to an earlier
update.

The journal is what makes a lost update heal without a full reset. A
receiver that reports the identifier of the update it holds asks the sender
for a repair. If the journal can reach that identifier, the sender rolls its
reference back, re-encodes against it, and sends the difference — so the
repair carries only what actually changed, and never carries stale pixels.

The journal is bounded by `JOURNAL_MAX_BYTES` (8 MiB) and
`JOURNAL_MAX_FRAMES` (240). When the bound is reached, the oldest entries
are dropped, and a base below the journal's floor cannot be reached: the
answer to that receiver is a self-contained update.

## 5.8 The measurements

The encoder reports what it observed through a **telemetry hook** the caller
installs. The hook receives one of two events:

- a **phase elapsed**: one phase of one encode took this long. The phases
  are `convert`, `compare`, `spans`, `pack`, `compress`, `reference`;
- a **self-check failed**: the encoder's own decoder rejected an update the
  encoder had just built.

The default hook discards everything, so a caller that does not care pays
nothing. The codec does not export metrics and does not log: a library does
not decide where its measurements go, and the application embedding it does.

## 5.9 The idle update

A surface that has not changed produces an **empty update**: no regions,
`update_bytes = 0`, and the base of the current reference. It paints
nothing, and it advances the applied identifier.

An idle update is how a sender keeps a receiver's view of the stream
current without saying anything about the content. A sender that has no
reason to send one MUST NOT send one at a rate that would cost more than
the content is worth; the reference implementation sends at most one per
`IDLE_UPDATE_INTERVAL_MS` (1000).

## 5.10 The configuration

The encoder's knobs are the codec's own, and a deployment maps them to
whatever its own environment uses:

| Knob | Default | What it does |
|---|---|---|
| `TESSELLIO_REFRESH_CELLS` | 131 072 | the refresh budget of §5.5 |
| `TESSELLIO_DELTA_DEFLATE_LEVEL` | 6 | the deflate level of a chained update's regions |
| `TESSELLIO_RESET_DEFLATE_LEVEL` | 9 | the deflate level of a self-contained update's regions |
| `TESSELLIO_ENCODER_THREADS` | the available parallelism | how many bands are encoded at once |
| `TESSELLIO_IDLE_UPDATE_MS` | 1000 | the idle interval of §5.9 |
| `TESSELLIO_REFRESH_BACKLOG_CELLS` | 262 144 | how much changed content may wait for the next update |
| `TESSELLIO_RESYNC_MIN_INTERVAL_MS` | 200 | the minimum interval between two repairs of one receiver |
| `TESSELLIO_RESET_MIN_INTERVAL_MS` | 250 | the minimum interval between two self-contained updates for one receiver |
