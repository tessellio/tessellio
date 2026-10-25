# 7. Limits

Every implementation enforces this table. The values are normative: a
sender MUST NOT produce an update that exceeds them, and a receiver MUST
reject one that does.

| Constant | Value | Enforced by |
|---|---|---|
| `MAX_SURFACE_DIMENSION` | 8192 | the sender's capture check + the receiver's validation |
| `MAX_SURFACE_CELLS` | 16 777 216 | the receiver's validation |
| `MAX_REGIONS_PER_UPDATE` | 64 | the sender's check + the receiver's validation |
| `MAX_REGIONS_PER_PART` | 32 | the sender's parter + the receiver's validation |
| `MAX_REGION_WIRE_BYTES` | 262 144 | the sender's split + the receiver's validation |
| `MAX_REGION_OPS_BYTES` | 1 048 576 | the sender's split + the receiver's bounded decompression |
| `MAX_PART_WIRE_BYTES` | 491 520 | the sender's parter |
| `MAX_PARTS_PER_UPDATE` | 8 | the sender's parter + the receiver's validation |
| `MAX_UPDATE_WIRE_BYTES` | 3 932 160 | the sender's budget + the receiver's validation |
| `RESET_MAX_PARTS` | 4 (≤ 1 966 080 B per self-contained update) | the sender's budget; the remainder becomes the next update's work |
| `DELTA_REFRESH_CELLS` | 131 072 | the sender's budget |
| `DELTA_REFRESH_MIN_CELLS` | 4 096 | the sender's progress guarantee |
| `DELTA_OPS_BUDGET_BYTES` | 393 216 | the sender's budget |
| `RESET_BAND_ROWS` | 256 | the sender's band encoder |
| `FILL_MIN_RUN` | 8 | the sender's op builder (shorter constant runs stay literal) |
| `JOURNAL_MAX_BYTES` | 8 388 608 | the sender's journal |
| `JOURNAL_MAX_UPDATES` | 240 | the sender's journal |
| `IDLE_UPDATE_INTERVAL_MS` | 1 000 | the sender's idle update |
| `RESYNC_MIN_INTERVAL_MS` | 200 | the receiver's repair reports |
| `RESET_MIN_INTERVAL_MS` | 250, per receiver | the sender, for repair-triggered plans |

## 7.1 How the caps relate

The caps are not independent, and they are chosen so that the largest
possible update fits the largest possible part count and vice versa:

```
MAX_UPDATE_WIRE_BYTES  = MAX_PARTS_PER_UPDATE * MAX_PART_WIRE_BYTES
                       = 8 * 491_520
                       = 3_932_160

RESET_PAYLOAD_BUDGET_BYTES = RESET_MAX_PARTS * MAX_PART_WIRE_BYTES
                           = 4 * 491_520
                           = 1_966_080
```

`MAX_SURFACE_CELLS` is `MAX_SURFACE_DIMENSION` squared, so a square surface
at the maximum dimension is exactly at the cell cap.

## 7.2 What the caps are for

The caps bound three things at once:

- **What a receiver can hold.** A receiver's surface is at most
  `MAX_SURFACE_CELLS` cells, and one update's regions are at most
  `MAX_UPDATE_WIRE_BYTES` in total.
- **What a peer can make a receiver allocate.** Every bound is checked
  before the allocation, and the decompression is bounded (§6.7).
- **What a sender can produce.** The refresh budget and the band encoder
  exist so that a sender never produces an update its own receiver would
  have to reject.

## 7.3 The caps are not negotiated

There is no negotiation, no downgrade, and no smaller variant. An update
that exceeds a cap is rejected, and a sender that cannot produce an update
within the caps reports an error rather than producing one that would be
rejected.

A deployment that needs a larger surface than 8192 × 8192 needs a different
codec, not a negotiated one.
