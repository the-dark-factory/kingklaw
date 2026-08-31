# The shelf

KingKlaw is a library, not a program. Each member is one decision a claw must
make, decided by a machine-checked core with a named verdict for every input.
Members are independent: taking one obliges you to nothing about the others.

## Built

### `admission/` — may this extension artefact load at all?

Six facts (operator · origin · integrity · proof · floor · containment) in,
one of nine verdicts out. Proven at level 2, truth-tabled over all 324 states.
See [FITTING.md](FITTING.md).

## Scoped, not built

These are named so the layout does not have to change when they arrive, and
so that nobody mistakes the shelf for the stock.

- **Grants and consent** — may this claw message that one, on whose authority?
- **Capability bounds** — is this action inside what was declared and agreed?
- **Provenance** — is this artefact what it claims, from where it claims?
- **Refusal vocabulary** — the shared verdict words. The thing that later
  makes cross-claw alerts possible: a refusal one claw can name is a refusal
  another claw can recognise.
- **Privacy family** — what may leave the machine (a proven egress boundary);
  who sees a thing rather than where its bytes rest; redaction and disclosure
  decided rather than remembered; consent as a checkable object.

## How a member is shaped

Every member follows the same three-layer shape, and the reason is that each
layer is checkable by someone who does not trust the layer below it:

1. **The core** — a SPARK Ada package specification, spec-only, `Pure`,
   importing nothing. Every operation is an expression function whose
   expression IS its definition, and whose postcondition is a conjunction of
   named theorems. It reads no clock, opens no file and holds no state.
2. **The fronts** — a command-line binary and a C shared library, each a
   thin surface over the same core. Neither holds a decision.
3. **The table** — the complete truth table over the member's whole input
   domain, checked against every front by an independent implementation.

A member is finished when its table is exhaustive, clean against both fronts,
and the core discharges at level 2 with no assumptions and no suppressed
warnings.
