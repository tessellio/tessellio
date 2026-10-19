# 1. Vocabulary

The codec describes a surface that changes. The words below are the codec's,
and they are the words the implementations use.

## 1.1 The two participants

- A **sender** produces updates. It captures content, compares it against
  what it believes the receiver holds, and encodes the difference.
- A **receiver** applies updates. It holds a surface, and it applies an
  update to it.

Where the two sit in a deployment — one machine, two machines, a chain of
machines — is the deployment's business, and the codec does not care. A
sender that sends to many receivers sends each of them an update built for
that receiver; the codec defines how one receiver's update is built, and
nothing about how a sender chooses between them.

## 1.2 The content

- A **surface** is a rectangle of **cells**. Its dimensions are its width and
  its height, in cells.
- A **cell** is one position of a surface. At wire fidelity a cell is a
  single 16-bit value (§2.2); in a capture it is four 8-bit channels
  (§2.3).
- A **capture** is the content a sender was given: a surface's dimensions and
  its cells, in the capture representation.
- A **pointer** is a shape drawn over a surface. It is not part of the
  surface; it is composited into it before the comparison (§2.4).

The codec does not say what a cell depicts. A cell may be a pixel, a
character, a tile of a texture, or a sample of something else: the codec
moves 16-bit values and never looks at one.

## 1.3 The units of state

- An **update** is a whole, identified object: the sender's statement that
  the surface now has some new content. An update is either **self-contained**
  or **chained** (§3.1).
- A **part** is one piece of an update. An update is applied whole: every
  part of it, or none of it (§3.3).
- A **region** is a rectangle of a surface, and the op stream that paints it
  (§4).
- An **op** is one instruction in a region's op stream.
- The **reference** is the sender's copy of the surface it believes the
  receiver holds. It is the thing the sender compares against, and the thing
  the sender advances (§5).

## 1.4 What the codec is not

The codec is not a transport. It does not:

- frame, address, or route its updates;
- retransmit, reorder, or expire them;
- measure a link, pace itself, or estimate a bandwidth;
- acknowledge anything.

Those are the transport's, and a transport that moves the codec's updates
without interpreting them is a transport that cannot corrupt them. Where
this document says an update is "lost" or "delayed", it means the transport
did that, not the codec.

The codec is also not an application. It does not capture content, composite
a pointer, draw a surface, or decide what a cell means. It takes a capture
and turns it into updates; it takes updates and turns them into cells.

## 1.5 The names in the implementations

| The codec's word | The Rust type | The TypeScript type |
|---|---|---|
| surface | `Surface` | `SurfaceCanvas` |
| capture | `CapturedFrame` | — (the browser receives cells, not captures) |
| update | `EncodedUpdate` | `AssembledUpdate` |
| part | `Part` | `UpdatePart` |
| region | `Region` | `UpdateRegion` |
| reference | `ReferenceJournal` | — (the browser holds no reference) |

The two implementations do not mirror each other one for one, and they are
not meant to: a sender holds a reference, a receiver does not, and a receiver
paints, a sender does not. The byte format is what they share.
