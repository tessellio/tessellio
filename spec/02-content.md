# 2. Content

## 2.1 The surface

A surface is a rectangle of cells. Its dimensions are two unsigned
integers, `width` and `height`, and they are bounded by the table of §7:
each dimension is at most 8192 cells, and the product is at most
16 777 216 cells.

A surface's cells are addressed by `(x, y)`, with the origin at the top-left,
`x` increasing to the right and `y` increasing downwards. A position
outside the surface does not exist: an implementation that is asked for one
reports an error rather than reading or writing past the end.

## 2.2 The cell format

At wire fidelity a cell is one unsigned 16-bit value:

```
R[15:11]  G[10:5]  B[4:0]
```

The cells of a surface are stored row-major, with no padding: the cell at
`(x, y)` is at offset `(y * width + x) * 2` bytes.

A receiver expands a value to four 8-bit channels with **bit replication**:

```
r8 = (r5 << 3) | (r5 >> 2)
g8 = (g6 << 2) | (g6 >> 4)
b8 = (b5 << 3) | (b5 >> 2)
a8 = 0xff
```

A sender reduces four 8-bit channels to a value with **truncation**:

```
r5 = r8 >> 3
g6 = g8 >> 2
b5 = b8 >> 3
```

These are the codec's only two conversion rules, and they are not
interchangeable: the reduction loses what the replication cannot restore, so
a value that has been reduced and expanded is not the value it came from.

## 2.3 The capture representation

A sender is given a **capture**: a surface's dimensions and its cells as four
8-bit channels each, packed `R, G, B, A`, row-major, with no padding. The
byte count is exactly `width * height * 4`.

The capture representation is what a capture device produces and what a
pointer is composited into (§2.4). The cell format of §2.2 is what travels.

The reduction of §2.2 happens **before** any comparison (§5.1). This is the
single most important rule in the codec: the sender compares the same 16-bit
values the receiver holds, so a cell that differs only in bits the wire does
not carry is not a change, and is never sent.

## 2.4 The pointer

A pointer is a shape with a hotspot, a size, and its own cells in the
capture representation. It is composited into the capture before the
comparison, and it is never sent separately.

The composition is the standard source-over:

- a cell whose alpha is 0 leaves the surface alone;
- a cell whose alpha is 255 replaces the surface's cell;
- a cell whose alpha is between the two is interpolated with the surface's
  cell.

A pointer that hangs off the edge of the surface is normal — a shape changes
as it moves — and the parts that do not fit are dropped, not rejected.

## 2.5 What a receiver ends up with

A receiver's surface holds cells at the capture representation: four 8-bit
channels per cell, expanded from the wire's 16-bit values by §2.2.

Two receivers that hold the same cells hold the same surface, whatever they
do with it afterwards.
