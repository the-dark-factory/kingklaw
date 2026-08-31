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

AGPL-3.0-or-later. Take it, fork it, rename it, rewrite it in your own
language from the truth table, or ignore it. A gate nobody can take is not a
gate.

One condition, and it is the only one: **if you improve the gate, the
improvement stays open.** You owe nothing to us — no attribution beyond the
licence header, no telemetry, no channel to maintain, no dependency on
anything of ours, no registration, no callback. You owe it to the next person
running a claw, who deserves to be able to read the gate that decides what
runs on their machine.

Two ways of fitting it, and the licence reaches them differently:

- **Run it as a separate binary** (`extension_admission_front`, facts in,
  verdict word and exit code out — see FITTING.md §2). Your claw calls a
  process. That is not linking, and the AGPL does not reach across it. Your
  claw stays under whatever licence you like, closed source included. This is
  the fitting we recommend anyway, because a gate in its own process is a gate
  a loaded plugin cannot rewrite.
- **Link the library** (`claw_admit.h`, `libkingklaw_admission`). Now the gate
  is inside your program, and the AGPL comes with it.

So: anybody may use it. Anybody who builds it into their own thing shares the
gate back. If that is the wrong trade, the truth table is printed in
FITTING.md §4, and a gate you write yourself from that table is yours and
carries none of this. The point was never the code.

---

## Hardware

Every line of Ada in this library was forged and proved on hardware bought
outright and sitting in a house in South Shields: a MacBook Pro that has run
the factory, the proofs and the writing without complaint for a year, a Ryzen
desktop with a couple of Radeons in it, and a small NVIDIA box that has twice
shut itself down from the heat. The whole proven output of the factory behind this library — 93 cores
— would have cost about six pounds at frontier API prices. It cost nothing,
because nobody was renting us the machines.

This is not a thinly veiled request for Apple or AMD to send private cloud
hardware to South Shields.

It would, however, be churlish to refuse.
