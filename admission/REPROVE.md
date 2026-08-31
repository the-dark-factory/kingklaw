# Rebuild it and re-prove it yourself

**SPDX-License-Identifier: AGPL-3.0-or-later**

This page exists because a prebuilt binary in a security component is worse
than useless if it has to be trusted. What makes the shared library worth
having is not that we built it — it is that you can build it, prove it, and
check that you got the same thing.

If you only ever read one thing here, read **Step 2**. Everything else is
convenience; that step is the security model.

## What you need

The free FSF **GNAT + GNATprove** package, and nothing else. It carries its
own compiler and `gprbuild` in its own `libexec`, so one install covers all
three steps. On most systems:

    # Debian/Ubuntu
    apt install gnat gnat-prove          # or fetch the FSF release
    # macOS / anywhere, via Alire
    alr toolchain --select gnat_native gprbuild
    alr install gnatprove

You do **not** need any of this to *use* the library. A host adopting it needs
the files in `lib/` and the header in `include/`. The toolchain is for the
person who wants to check the artefact, which may or may not be the same
person.

## Step 1 — build

    ./build-lib.sh

That produces `lib/libkingklaw_admission.{so,dylib}`, the command-line front
at `front/extension_admission_front`, and the C checker. It proves nothing,
and says so.

## Step 2 — PROVE. This is the step that matters.

    cd src && gnatprove -P proof.gpr -f -U --level=2

Expect **zero unproved checks and zero errors**, and expect to see
`postcondition proved` for each of `Meets_Floor`, `Decide`, and every function
in the ABI package. Anything else and the artefact is not what it claims —
refuse it. That refusal *is* the security model: a tampered or defective core
fails to discharge on your machine, and nothing about our machine can change
that.

What is being proved: that the verdict chain and the fifteen postcondition
conjuncts of `Decide` agree over the *whole* input domain, and that every
unrecognised integer arriving at the C boundary decodes to the least
permissive value of its position. Not sampled. Not tested. Discharged.

Read the contracts yourself while you are there — they are the specification.
`src/extension_admission_pkg.ads` is about a hundred lines of which most are
comments.

## Step 3 — check both fronts against the table

    go run ./tools/tablegen -out front/TABLE.tsv -check front/extension_admission_front
    ./tools/abicheck/abicheck front/TABLE.tsv

`TABLE.tsv` is the **complete** 324-row state space (2 × 3 × 3 × 3 × 3 × 2),
not a sample. `tablegen` is a deliberately independent second implementation
of the decision, written from the prose specification rather than from the
Ada, so agreement across all 324 rows means the specification was implemented
the same way twice by two different routes. `abicheck` drives the same table
through the C ABI, and additionally probes every fact position with
unrecognised integers to confirm each one falls to the least permissive value.

Both must be clean. Either one failing means the artefact and its table
disagree, and the artefact loses.

## Step 4 — did you get the same binary?

    shasum -a 256 -c DIGESTS.sha256

**Be honest about what this can and cannot tell you.** The *source* digests
will match: those files are bytes, and bytes are bytes.

The **binary** digests almost certainly will not, and that is not a red flag.
The shared library and the front embed a GNAT runtime, and the artefact
therefore depends on the exact compiler version, target triple, system SDK
and link order of the machine that built it. **This build is not reproducible
across machines, and we are not going to pretend otherwise.** A digest that
only matches when you have our exact toolchain is a digest that proves you
have our toolchain, not that you have our software.

So the chain of trust here does not run through the binary's hash. It runs
through Steps 2 and 3: the source is fixed and hashable, the proof discharges
from that source on your machine, and the built binary agrees with the
complete truth table on your machine. A binary that passes those two checks
does the same thing as ours whether or not it is byte-identical to ours —
and *that* is the property you actually wanted.

If byte-identical builds matter to you, build it in a container pinned to one
toolchain and publish that container's digest alongside. We have not done
that work; it is real work, and claiming it without doing it would be exactly
the kind of thing this page exists to avoid.

## Step 5 — if you would rather not have any of this

Read `front/TABLE.tsv` and write the decider yourself, in your own language,
in about forty lines. The table is the specification in its most portable
form, the licence permits it, and nothing here is offended by it. A gate you
wrote from a table you checked is a better gate for you than one you took on
faith.
