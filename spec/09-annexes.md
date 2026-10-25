# 9. Annexes

## 9.1 The five hand-derived vectors

Every payload below is a stored DEFLATE block: `01` (`BFINAL=1`,
`BTYPE=00`), `LEN` (u16le), `~LEN` (u16le), then the op bytes. The
`part proto` hex is the full envelope byte string, shown byte by byte;
re-encoding the decoded message must reproduce it exactly.

**V1 — the empty update.** `update_id=7, base_update_id=6, width=8,
height=4`. No regions.

Part proto (12 B): `08 07 10 06 18 08 20 04 30 01 40 08` — `update_bytes`
and `part_index` are proto3 defaults and are omitted.

Expected: the surface is unchanged, `applied_update_id = 7`.

**V2 — a literal run (one `SPAN`, sparse coverage).** `update_id=2,
base_update_id=1, width=8, height=4, part_count=1, update_bytes=22`, one
region `{x=2, y=1, width=4, height=2}`.

Part proto (48 B):
`08 02 10 01 18 08 20 04 30 01 38 16 40 08 4a 20 08 02 10 01 18 04 20 02 2a 16 01 11 00 ee ff 01 00 00 02 00 00 04 00 00 f8 e0 07 1f 00 ff ff 00`.

Op stream (17 B): `01 00 00` (`ROW 0`), `02 00 00 04 00` (`SPAN x=0 len=4`),
the cell values `00 f8 e0 07 1f 00 ff ff` (`0xF800`, `0x07E0`, `0x001F`,
`0xFFFF`), `00` (`END`). Payload (22 B):
`011100eeff010000020000040000f8e0071f00ffff00`.

Expected: the region's first row is painted, its second row is never written
and stays untouched.

**V3 — full coverage, several rows, one `FILL` each (self-contained).**
`update_id=3, base_update_id=0, width=6, height=3, part_count=1,
update_bytes=36`, one region `{x=0, y=0, width=6, height=3}`.

Part proto (56 B):
`08 03 18 06 20 03 30 01 38 24 40 08 4a 2a 18 06 20 03 2a 24 01 1f 00 e0 ff 01 00 00 03 00 00 06 00 00 00 01 01 00 03 00 00 06 00 ff ff 01 02 00 03 00 00 06 00 10 84 00`.

Op stream (31 B): `ROW 0` + `FILL x=0 len=6 0x0000`; `ROW 1` + `FILL len=6
0xFFFF`; `ROW 2` + `FILL len=6 0x8410`; `END`. Payload (36 B):
`011f00e0ff010000030000060000000101000300000600ffff0102000300000600108400`.

A row-maximum run needs no splitting (`x` and `len` are `u16`, and the width
is at most 8192). The painted surface is black, white, `(132, 130, 132)`. A
variant with a missing row or an intra-row gap is rejected with
`COVERAGE_INVALID`; the corpus carries both mutants.

**V4 — several regions, a skipped row (sparse coverage).** `update_id=9,
base_update_id=8, width=8, height=4, part_count=1, update_bytes=46`, two
regions: A `{x=0, y=0, width=8, height=2}` (payload 30 B) and B `{x=0, y=2,
width=8, height=2}` (payload 16 B).

Part proto (78 B):
`08 09 10 08 18 08 20 04 30 01 38 2e 40 08 4a 24 18 08 20 02 2a 1e 01 19 00 e6 ff 01 00 00 02 01 00 02 00 1f f8 ff 07 01 01 00 02 06 00 02 00 1f f8 ff 07 00 4a 18 10 02 18 08 20 02 2a 10 01 0b 00 f4 ff 01 00 00 02 03 00 01 00 00 00 00`.

A's payload is `011900e6ff01000002010002001ff8ff0701010002060002001ff8ff0700`
(`ROW 0`, `SPAN x=1 len=2` of `0xF81F, 0x07FF`; `ROW 1`, `SPAN x=6 len=2` of
the same pair; `END`) and paints `(1,0)` and `(2,0)` magenta/cyan and `(6,1)`
and `(7,1)` the same pair. B's payload is
`010b00f4ff0100000203000100000000` (`ROW 0`, `SPAN x=3 len=1` of `0x0000`,
`END`) and paints `(3,2)` black. Row 3 is never written.

**V5 — one update in two parts.** `update_id=10, base_update_id=9, width=8,
height=4, part_count=2, update_bytes=32`.

Part 0 (`part_index=0`, 42 B):
`08 0a 10 09 18 08 20 04 30 02 38 20 40 08 4a 1a 08 01 10 01 18 01 20 01 2a 10 01 0b 00 f4 ff 01 00 00 02 00 00 01 00 00 f8 00`
(region `{x=1, y=1, width=1, height=1}`, red; payload
`010b00f4ff010000020000010000f800`).

Part 1 (`part_index=1`, 42 B):
`08 0a 10 09 18 08 20 04 28 01 30 02 38 20 40 08 4a 18 08 02 18 01 20 01 2a 10 01 0b 00 f4 ff 01 00 00 02 00 00 01 00 e0 07 00`
(region `{x=2, y=0, width=1, height=1}`, green; payload
`010b00f4ff0100000200000100e00700`).

Expected: the update is applied only after both parts (the payloads sum to
32 = `update_bytes`); part 0 alone is neither applied nor acknowledged; a
receiver that sees part 1 first refuses the update.

## 9.2 The measured bounds

The codec's memory is a function of the caps of §7: one reused cell workspace
and one reference buffer (4.15 MB each at 1920×1080), a lazily allocated
rebase scratch of the same size, per-region staging bounded by one update's
payload cap (3.93 MB), and the undo journal bounded at 8 MiB / 240 updates.
A receiver holds one surface plus a reusable image buffer and a 256 KiB
cell-to-channel lookup table.

Measured on a loaded 16-core machine: a chained update encodes at ≈ 4 ms,
including the capture-to-cell conversion; a 1080p self-contained update
encodes at 7.53 ms and ships 82 699 bytes in 5 regions across ≤ 4 parts. A
one-cell pointer move costs 92 bytes, typing a 600×40 area 2 466 bytes, a
600×400 window drag 1 633 bytes, a 900×620 scroll 4 624 bytes, and a
full-width 1680×920 scroll 16 380 bytes — still a chained update. A
whole-viewport shift off the line period — every line of the surface dirty
at once — costs 40 960 bytes and stays a chained update. A 640×360
noisy area converges in two updates (259 918 bytes, then 203 312 bytes), and
an unchanged surface costs 0 bytes and no compression work.

These are measurements of the reference implementation, not requirements. A
different implementation will measure differently; the corpus, not the
measurement, is the contract.

## 9.3 The error vocabulary

The reference implementation's errors are a closed set, so a caller can
match on them and act:

| Error | What it means |
|---|---|
| `InvalidSurface` | the surface's dimensions, or the length of its content, are invalid |
| `RegionOutOfBounds` | a region lies partly outside the surface it belongs to |
| `InvalidRegion` | a region's op stream does not obey the grammar |
| `TooLarge` | the content would exceed one of the caps of §7 |
| `Budget` | the update would not fit the budget the caller gave it |
| `Encode` | the content could not be encoded |
| `Envelope` | the compressed envelope could not be produced or read |
| `UnsupportedFormat` | the content's cell format is not the one the codec encodes |

A message is carried for a human, not for a program: the variants are what a
program matches on.

## 9.4 The repair reasons

A receiver reports why it could not advance with one of eight reasons:

| Reason | What it means |
|---|---|
| `BASE_MISMATCH` | the update continues an update the receiver does not hold |
| `INCOMPLETE_UPDATE` | the update is malformed, or its parts do not agree |
| `DECODE_ERROR` | a region's op stream does not obey the grammar |
| `COVERAGE_INVALID` | a self-contained update's regions do not cover the surface |
| `UNKNOWN_CODEC` | the update's codec is not 8 |
| `QUEUE_OVERFLOW` | the receiver could not hold the update |
| `GEOMETRY_MISMATCH` | the update's geometry differs from the receiver's surface |
| `PART_GAP` | a part is missing, or arrives out of order |

The set is closed on purpose: a sender that repairs an update must know
what was wrong with it, and a reason outside the set is a defect rather than
a variant.
