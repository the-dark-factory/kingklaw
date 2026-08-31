# KingKlaw

**KingKlaw. He bows to none.**
**Puts the king in the claw.**

A cybersecurity and privacy library for claws: machine-checked cores for the
decisions every claw must make and none can afford to get wrong.

The reversal in the name is the whole design. This is not a king *over* the
claws — it is a king *inside* each one. Authority moves into the owner's box,
not into anyone's datacentre. Concretely that means the gate has no remote
authority, no callbacks home, no telemetry, and no vendor whose permission it
waits on. It answers to the machine's owner and refuses on the evidence.

Every claw its own kingdom; the king decides what may pass the gate.

## What is here

| Member | What it decides | State |
|---|---|---|
| [`admission/`](admission/) | May this extension artefact load at all? | **built, proven, in use** |

Others are scoped in [MEMBERS.md](MEMBERS.md) and are not built yet. The
library is laid out so they can join without anything here moving.

## Member one — admission

Six facts in, one of nine verdicts out. It names no bundle, no plugin, no
manifest field, no file layout and no language, so any host that can answer
six questions can use it — including hosts that answer "no proofs" and "no
containment", which are honest answers that get honest verdicts.

    extension_admission_front requested attested verified reproved floor_none contained
    admit                                                                    # exit 0

    extension_admission_front requested attested mismatch reproved floor_none contained
    refuse_integrity_mismatch                                                # exit 1

The decision is a SPARK Ada package whose contract *is* its definition,
discharged by GNATprove at level 2 over the whole input domain — not sampled
by tests. A complete 324-row truth table ships beside it and is checked
against the built binary by two independent checkers.

Three ways to call it, in increasing order of intimacy:

- **as a command** — `extension_admission_front`, argv in, one word out,
  exit 0 admit / 1 refuse / 2 malformed. Nothing to link.
- **as a C call** — `libkingklaw_admission`, two exported symbols, one
  header. For loaders that are synchronous and cannot spawn a process.
- **as source** — rebuild and re-prove it yourself. This is the one that
  matters: everything else is a convenience over an artefact you can
  reconstruct.

## Start here

- **[FITTING.md](FITTING.md)** — what the six facts mean, how a host builds
  each one, where in a loader the call belongs, what to do with each verdict,
  the troubleshooting table, and the honest limits.
- **[admission/REPROVE.md](admission/REPROVE.md)** — rebuild it and re-prove
  it on your own machine, with your own toolchain, and check you got the same
  artefact.

## Licence

MIT. Take it, fork it, rename it, rewrite it in your own language from the
truth table, or ignore it. Nothing is asked in return: no attribution
requirement, no reciprocity, no dependency on anything of ours, no channel to
maintain. A gate nobody can take is not a gate.
