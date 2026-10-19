# 6. The decoder

## 6.1 The validation order

Every receiver applies the checks in this order, and the first failure
rejects the **whole** update. A receiver MUST NOT apply a partially
validated update, and MUST NOT paint anything from one.

```
validate_part(part):
  1  codec == 8                                          else reject(UNKNOWN_CODEC)
  2  update_id >= 1                                      else reject(INCOMPLETE_UPDATE)
  3  base_update_id == 0 or base_update_id < update_id    else reject(INCOMPLETE_UPDATE)
  4  1 <= width <= 8192, 1 <= height <= 8192,
     width * height <= 16_777_216                        else reject(GEOMETRY_MISMATCH)
  5  0 <= part_index < part_count <= 8                   else reject(PART_GAP)
  6  0 <= update_bytes <= MAX_UPDATE_WIRE_BYTES          else reject(INCOMPLETE_UPDATE)
  7  regions.len() <= MAX_REGIONS_PER_PART               else reject(INCOMPLETE_UPDATE)
  8  per region: x >= 0, y >= 0, width >= 1, height >= 1,
     x + width <= surface width, y + height <= surface height
                                                       else reject(DECODE_ERROR)
  9  per region: 0 < payload.len() <= MAX_REGION_WIRE_BYTES
                                                       else reject(DECODE_ERROR)
 10  regions ascending by (y, x) and pairwise disjoint     else reject(DECODE_ERROR)
```

The order matters: the cheap checks come first, so a malformed update is
rejected before anything is allocated for it, and the geometry is checked
before the regions, so a region is never validated against a surface that
does not exist.

The reasons are a closed set: `BASE_MISMATCH`, `INCOMPLETE_UPDATE`,
`DECODE_ERROR`, `COVERAGE_INVALID`, `UNKNOWN_CODEC`, `QUEUE_OVERFLOW`,
`GEOMETRY_MISMATCH`, `PART_GAP`. A receiver that fails for a reason that is
not one of these has a defect, not a different codec.

## 6.2 The assembly

The parts of update `U` arrive as `part_index` `0, 1, …, part_count-1`. A
different `update_id` before completion discards the partial update; a first
part that is not index 0 refuses the update; the parts of one update must
agree on `part_count`, `update_bytes`, `base_update_id`, and geometry; and
the sum of every part's region payload bytes must equal `update_bytes`.

Any violation rejects the update.

## 6.3 The application

After every part has arrived and every region has been decompressed and
validated, the receiver applies the update:

```
R0  if U.base != 0 and U.update_id <= applied_update_id:
      discard as stale, no repair — the applied state is already newer
R1  if U.base == 0: the geometry is authoritative. If (w, h) differs from
      the surface's: resize the surface, fill it opaque black.
    else if (w, h) differs from the surface's:
      reject(GEOMETRY_MISMATCH) → repair
R2  if U.base != 0 and U.base != applied_update_id:
      reject(BASE_MISMATCH) → repair
R3  decode and validate every region's ops (§4.3, and the coverage rule of
    §4.4); any failure rejects the update with no write to the surface
R4  apply every region
R5  applied_update_id = U.update_id
```

R0 comes first: an update that is older than what has been applied carries
no information, and applying it would move the surface backwards.

R3 comes after R2 and before R4: a receiver that painted half of a broken
update would hold a surface that no sender ever described.

## 6.4 What the receiver acknowledges

A receiver acknowledges **only what it fully applied**. An update that was
refused, incomplete, or dropped is never acknowledged.

This makes the acknowledged identifier a contiguous low-water mark by
construction, and it is what lets a sender know that the surface it holds
is the surface the receiver holds.

A receiver that cannot advance MUST report it, with the identifier of the
update it does hold and the reason it could not advance. The report is a
**repair request**, not a demand for a reset: the sender's answer is a
repair of what changed, and a self-contained update is the answer to a
geometry change only.

A receiver MUST rate-limit its reports, so that a receiver that cannot
advance at all does not flood the sender with requests. The reference
implementation reports at most one per `RESYNC_MIN_INTERVAL_MS` (200),
coalescing several failures into one that carries the newest held
identifier.

## 6.5 The duplicate

Application is idempotent by `(update_id, part_index)`: a receiver that has
already applied a part MUST NOT apply it twice. A transport that
retransmits a part is therefore harmless, and a receiver needs no separate
de-duplication state.

## 6.6 The stale surface

A receiver whose surface is stale — because it missed an update, or because
the sender could not reach its base — still holds a coherent surface. It is
the *sender's* knowledge that is stale, and the repair of §6.4 is what
restores the agreement.

A receiver MUST NOT clear its surface when it cannot advance. Showing the
last known surface, and reporting that it is stale, is strictly better than
showing nothing: the content is right up to the point where it stopped.

## 6.7 The bounds a receiver enforces

A receiver MUST enforce the caps of §7 on everything it receives, and it
MUST do so before it allocates for it:

- the number of regions in a part;
- the size of a region's payload;
- the size of a region's decompressed op stream;
- the size of the whole update;
- the dimensions of the surface.

A receiver that decompresses without a bound is a receiver that a peer can
make allocate without limit. The reference implementation aborts the
decompression as soon as the output would exceed the cap.
