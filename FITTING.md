# Fitting the admission gate

**KingKlaw. He bows to none.**

This is a fitting guide, not a pitch. It tells you what the six facts mean,
how your host builds each one, where in your loader the call belongs, what to
do with each of the nine verdicts, and — at some length, because it is the
part most likely to matter to you — what this gate does **not** do.

The gate answers to the machine's owner. It has no remote authority, makes no
network call, reads no clock, opens no file, keeps no state, and phones
nobody. There is no vendor whose permission it waits on, and no way for us to
change what it decides on your machine. That is not a promise; it is a
property of a `Pure` package that imports nothing, and you can check it by
reading about a hundred lines of source.

---

## 0. Before anything else: is this even your problem?

This gate answers exactly one question: **may this artefact load at all?**

It is complementary to, and no substitute for, whatever you already do about:
sandboxing, capability models, permission prompts, install-time policy hooks,
static analysis, model checking, review. Those answer *what may an extension
do*, *is this code well-behaved*, and *did a human agree*. Different
questions, all of them worth answering, none of them this one.

If you already have an install-time policy hook and a sandbox, this gate adds
one thing: a **named decision with a proved contract at the load site**,
instead of a decision that emerges from several functions each returning no
error. If that is not a gap you have, you do not need this.

## 1. The adoption path — advisory first, and off by default

**Do not turn this on as an enforcing gate on day one. It will refuse things,
and you will not yet know whether it is right.**

The recommended sequence, and the only one we would defend:

1. **Off.** Ship nothing. Merge nothing. Read section 3 and decide whether
   your host can honestly build the six facts at all. If it cannot build one
   of them, the honest answer is a fail-closed value for that field, and you
   should know what that costs you before you write any code.
2. **Advisory.** Wire the call in, log the verdict, and **ignore it**. Let it
   run over your real extension set for as long as it takes to stop
   surprising you. Advisory mode is not a lesser adoption; it is the only way
   to find out what enforcement would cost without paying it.
3. **Enforcing, at a floor you chose.** Turn it on. Start with
   `FLOOR_NONE`, which demands no proofs from anything, and raise it only if
   and when your ecosystem has something to raise it to.
4. **Never, if it does not suit you.** This is a real outcome. Nothing here
   is worse for having been declined.

The gate must be **optional and off by default** in whatever you ship. That
is not a courtesy to your users, it is the only configuration that lets step
2 exist.

### The thing you should know before step 1

Run against a host where extensions execute in-process at the host's own
trust, with no proofs anywhere in the ecosystem, and with the containment
fact answered honestly, **this gate refuses everything**. Every extension.
Day one.

That is not a bug and it is not a bluff. It is the gate reporting your
architecture back to you accurately, and the correct response is very often
"then we will not enforce that fact yet". Sections 3.6 and 5 tell you exactly
which knob that is and what turning it costs. We would rather you know this
in paragraph twenty than discover it in CI.

## 2. The shape of the thing

Three ways to call it. Pick the least intimate one that works.

### As a command (nothing to link)

    extension_admission_front OPERATOR ORIGIN INTEGRITY PROOF FLOOR CONTAINMENT

      OPERATOR    : requested | absent
      ORIGIN      : attested | unattested | revoked
      INTEGRITY   : verified | mismatch | unchecked
      PROOF       : reproved | carried | absent
      FLOOR       : floor_reproved | floor_carried | floor_none
      CONTAINMENT : contained | uncontained

    exit 0  the word "admit" on stdout
    exit 1  a refusal word on stdout
    exit 2  malformed input, diagnostic on stderr, NOTHING on stdout

The floor tokens carry a `floor_` prefix on purpose: transposing arguments 4
and 5 is then invalid in **both** positions and exits 2, rather than silently
deciding a different question.

If your loader can spawn a process, use this. There is nothing to link, no
ABI to get wrong, no memory to manage, and the failure mode of a subprocess
is a failure mode you already understand.

### As a C call (for loaders that are synchronous)

    #include "claw_admit.h"

    int32_t facts[6] = {
        CLAW_OPERATOR_REQUESTED, CLAW_ORIGIN_ATTESTED, CLAW_INTEGRITY_VERIFIED,
        CLAW_PROOF_ABSENT,       CLAW_FLOOR_NONE,      CLAW_UNCONTAINED
    };
    char verdict[40];
    int32_t rc = claw_admit_decide(facts, verdict, sizeof verdict);
    /* rc == 0 admit · 1 refuse · 2 malformed call.
       Treat anything other than 0 as "do not load" and you are correct
       under every outcome, including the ones you did not think about. */

The shared library exports exactly **two** symbols —
`claw_admit_decide_codes` and `claw_admit_status_codes` — both taking six
`int32_t` and returning one. No buffers, no pointers, no lengths, no strings,
no allocation, no globals, no callbacks, and nothing that can throw across
the boundary. The entire class of memory faults at a C boundary has nowhere
to occur.

`claw_admit_decide` above is a static inline **in the header**, roughly
fifteen lines, which maps the returned ordinal to a word from a table that is
also in the header. Read it; delete it if you would rather map the ordinal
yourself. The words are data in a header rather than code in a library
precisely so you can check the mapping instead of trusting it.

Both entry points are **total**: any `int32_t` at all is accepted, and every
value the library does not recognise is read as the **least permissive** value
of its position. A garbled call refuses. It cannot admit. That direction is
proved, not merely intended — see §3.7.

### As source

Rebuild it and re-prove it. [`admission/REPROVE.md`](admission/REPROVE.md).
Or read `admission/front/TABLE.tsv` — the complete 324-row state space — and
write the decider yourself in forty lines of whatever you already use. The
licence permits it and nobody here minds. **A gate you wrote from a table you
checked is a better gate for you than one you took on faith.**

## 3. The six facts, and how your host builds each one

The tuple is deliberately small and deliberately says nothing about bundles,
plugins, manifests, file layouts or languages. Every field is something a host
can answer from things it already possesses. If your host cannot answer one
honestly, there is a fail-closed value for it, and taking that value is the
correct move — not inventing a better-sounding one.

### 3.1 OPERATOR — did a human explicitly ask for **this** artefact, **now**?

`requested` means a fresh human act initiated this load. `absent` means
something else did: a schedule, an auto-update, a standing grant, a peer, a
restart.

**How to build it.** Most hosts already know. If your install command is a
CLI verb a person types, that is `requested`. If your loader also runs on
boot, on reconnect, or on a poll, those are `absent` and they should be —
that is the point of the field. A standing grant given last month is not a
human asking now.

**Fail-closed value:** `absent`. If you cannot tell, say you cannot tell.

**If you answer `absent` everywhere**, you will get `refuse_operator_absent`
for everything, which is the field telling you it is the wrong fact for your
architecture. Either find the human act, or — if your host genuinely has no
human in the loop by design — set it to `requested` at the site where your
host's own authorisation has already been satisfied, and write down that you
have redefined it that way.

### 3.2 ORIGIN — does a pinned authority vouch for identity → digest, and does that assertion still stand?

`attested` · `unattested` · `revoked`.

**How to build it.** You need three things: an authority your host has
*pinned* (not merely reachable), an assertion from it binding this artefact's
identity to a specific digest, and a check that the assertion has not been
withdrawn. A registry that serves you a digest over TLS is not an attestation
— it is a fetch. The question is whether something you pinned *signed* the
binding.

**Fail-closed value:** `unattested`. Note that `unattested` deliberately
covers two situations — no authority known, and a known authority silent
about this artefact. A verdict word need not recover its state; a state must
determine its verdict.

**Be honest here.** Most ecosystems today cannot construct a strong
`attested`, ours included. If your best is trust-on-first-use over an
unsigned index, then either answer `unattested`, or answer `attested` and
record in your own log that it rests on TOFU. What you must not do is let a
TOFU pin read, downstream, as a signature. The value of this field before you
have signing is that it makes the gap **named** rather than invisible, and
makes signing a thing with a purpose rather than a chore.

### 3.3 INTEGRITY — do the bytes about to load hash to what was attested?

`verified` · `mismatch` · `unchecked`.

**How to build it.** Hash the bytes you are about to evaluate, and compare
against the digest the authority recorded. Not the bytes you downloaded an
hour ago; the bytes you are about to use.

**Fail-closed value:** `unchecked`.

**Three values, not two, and this matters.** `unchecked` must never collapse
into `verified` — "nobody looked" and "we looked and it matched" are
different states with different remedies. And `mismatch` deserves its own
refusal from `unchecked`, because `mismatch` means the delivery was altered
(re-fetch it, *never* repair it) while `unchecked` means go and look.

**Origin and integrity are not redundant.** Integrity says "these are the
bytes someone named". Origin says "and that someone was entitled to name
them, and has not withdrawn it". An attacker who controls the registry names
the digest of their own artefact and integrity verifies perfectly. Both, or
neither is worth having.

### 3.4 PROOF — the artefact's honest proof rung

`reproved` (proofs re-derived on this machine) · `carried` (ships proofs, read
but not re-run here) · `absent` (carries none).

**How to build it.** If your ecosystem has no notion of shipped proofs, the
answer is `absent`, for everything, always, and **that is fine**. The tuple
has to be constructible by a host with no proofs or it is not neutral — it is
somebody's manifest wearing a hat.

**Fail-closed value:** `absent`.

### 3.5 FLOOR — the minimum rung **you** demand at **this** load site

`floor_reproved` · `floor_carried` · `floor_none`.

**This is the field that lets one gate serve hosts with entirely different
ambitions, and it is the one to understand if you read nothing else.**

The proof requirement is a fact *handed in by you*, not a rule baked into the
theorem. `floor_none` is an honest, valid, zero-cost answer, and it is where
you should start. A host at `floor_none` still gets operator, origin,
integrity and containment decided for it, and can raise the floor later
without a new gate, a new proof, or anyone's permission.

**Fail-closed value:** `floor_reproved` — the *strictest*, because the floor
is your demand, and a garbled demand must be read as the highest one, never
as "no requirement". This is the one position where the fail-closed direction
is the numerically largest value rather than the smallest; if you are writing
your own decoder from the table, do not get this backwards.

Note also that the floor should be **per load site**, not global. A host may
reasonably demand `floor_reproved` for something loaded into a privileged
context and `floor_none` for something loaded into a sandbox.

### 3.6 CONTAINMENT — will it run inside a boundary you control?

`contained` · `uncontained`.

**How to build it.** This is a property of **your loader's own plan**, not of
the artefact — which is precisely why every host can answer it without
agreeing with any other host about anything. Will this code run in a worker,
a container, a subprocess, a VM, an interpreter you control? Then
`contained`. Will it be evaluated in your own process at your own trust, able
to reach your globals, your module cache, your file handles and your network?
Then `uncontained`.

**Fail-closed value:** `uncontained`.

**The rule you cannot configure away.** There is exactly one:

> `uncontained` **and** `absent` proof ⟹ `refuse_uncontained_unproven`,
> whatever the floor says.

`floor_none` is your right. Loading unproven code *at your own process trust,
inside no boundary at all*, is the one state where the gate will not take
your word for it. We are not going to soften that to make the gate easier to
adopt; softening it would make the gate worthless, and you would be right not
to want a gate that could be talked out of its only unconditional rule.

**What this costs you, stated plainly:** if your extensions run in-process
and none of them carry proofs, this rule refuses all of them. See §1 and §5.
Your routes to `admit` are containment or proof, and both are yours to
choose, on your timetable, or never.

### 3.7 What is deliberately **not** in the tuple

Because an offer that hides its shape is not made in good faith:

| Not a fact here | Why |
|---|---|
| extension **name, version, semver range** | Identity is your business. A decider that reads names invites name-based policy, which always rots. |
| **capability declarations** — network, filesystem, wall-time, tokens, model tier | Putting them in would mean you must build a capability model *before* you can use the gate: annexation by prerequisite. `uncontained` captures the one bit that actually decides, in a form you can answer today. |
| **signature algorithm, key, issuer** | Cryptography belongs outside the core. Origin is the *conclusion* of that work, not the work. |
| **timestamps, expiry, clocks** | The core reads no clock and holds no state. Staleness, if you want it, resolves to `revoked` before the gate is consulted. |
| **the operator's identity, role, RBAC scope** | Which human, and whether they were entitled, is your authorisation. The gate asks only whether a human acted. |
| **prior installs, upgrade vs fresh** | Different semantics in every ecosystem. Stays out. |
| **trust "levels", scores, tiers, reputation** | Not a fact. A summary of facts, computed by whoever benefits from the answer. |

## 4. The nine verdicts, and what to do about each

Evaluation order is part of the design: a refusal names the **first** failing
fact in the fixed order operator → origin → integrity → proof → floor →
containment. The cheap, universally actionable refusals fire before the
architectural one, so a host with no containment story at all still gets real
value on day one: a forged, altered or revoked artefact is refused long before
the containment question is reached.

### Troubleshooting table

For the maintainer woken at 2am who does not read Ada, and should not have to.
Every refusal is a named verdict with a documented meaning; nothing here
requires reading a line of the core.

| Verdict | What it means | What to check | Override in advisory mode |
|---|---|---|---|
| `admit` | Every admitting fact held. | — | — |
| `refuse_operator_absent` | Nothing recorded a human asking for this artefact now. | Is the load path a scheduled job, an auto-update, a restart, or a standing grant? If a human really did act, your OPERATOR fact is being built at the wrong place — build it where the human act is, not where the load happens. | Log and proceed; then fix where the fact is built. This one is almost always a wiring bug, not a real refusal. |
| `refuse_origin_revoked` | A pinned authority has **withdrawn** this artefact. | Your registry's revocation list. **Do not work around this one.** It is the only verdict that means somebody deliberately said no. | Do not. If you must, treat it as an incident, not a config change. |
| `refuse_origin_unattested` | No pinned authority vouches for this identity→digest binding — or a known authority is silent about this artefact. | Do you have an attestation mechanism at all? Is this artefact simply not in it (sideloaded, local dev, first-party)? | Log and proceed. Expect this verdict for *everything* until you have registry attestation; that is the field doing its job. |
| `refuse_integrity_mismatch` | The bytes hash to something other than what was attested. **The delivery is altered.** | Re-fetch from the source. **Never repair in place.** If it recurs, you have a real supply-chain problem, a corrupted cache, or a mirror serving different bytes. | Do not, without understanding why. This is the verdict the gate exists for. |
| `refuse_integrity_unchecked` | Nobody hashed the bytes. | Is your loader hashing what it is about to evaluate, or trusting an earlier check over different bytes? Is the digest missing from the registry entry? | Log and proceed while you wire hashing in. Then stop. |
| `refuse_proof_absent` | This load site demands a proof rung and the artefact carries none. | **Your FLOOR setting.** You asked for proofs at a site whose artefacts have none. | Lower the floor to `floor_none` — that is a supported, honest configuration, not a downgrade. |
| `refuse_proof_not_reproved` | The artefact carries proofs, but no prover ran here. | Whether you meant `floor_reproved` (re-derive on this machine) or `floor_carried` (trust shipped proofs). | Lower the floor to `floor_carried`, or install a prover. |
| `refuse_uncontained_unproven` | Unproven code, at your own process trust, in no boundary. | Your CONTAINMENT fact. Is it honestly `uncontained`? If so, this is the architectural refusal and it is telling you the truth. | Advisory mode, or answer `contained` at sites where you genuinely do contain. **Do not answer `contained` where you do not** — a fact you fabricate buys you an `admit` you did not earn, and the gate cannot tell. |
| *(anything else, or no answer)* | The gate did not decide. | Missing library, missing binary, wrong ABI, a crash. | Never treat as admit. See §6. |

**Who to contact.** The source and its proofs are public and permissively
licensed; there is no support contract and none is implied. File an issue on
whatever fork you took, or fix it yourself — the core is about a hundred
lines and the table is the specification. If the gate refuses something it
should not, the fastest honest diagnosis is: print the six facts you handed
it, find the row in `TABLE.tsv`, and see whether the table agrees with the
binary. If it does, your facts are wrong. If it does not, the artefact is
broken and you should stop using it.

## 5. The honest limits

Read this section before you decide, not after.

### 5.1 It binds against artefacts, not against an adversary already inside

If an extension has already been evaluated in your process at your own trust,
it can rewrite the loader, the cache, the wrapper, the binding, and the gate
itself. Nothing in a library can prevent that; it is the definition of
running at your trust.

So the guarantee on offer is a **supply-chain** guarantee, not a containment
one. It protects the *first* load in a fresh process and it protects you
against artefacts that are forged, altered, unattested or revoked. It does
not protect you against an adversary who is already in-process, and any
document that told you otherwise would be lying to you.

This is exactly why `refuse_uncontained_unproven` exists and why it is
unconditional.

### 5.2 An extension-shaped gate cannot protect loads that preceded it

The gate fires where you put it. Anything loaded before that point — earlier
in boot, by a different code path, by a native `require` your wrapper does not
dominate, by a bundled first-party module — was never decided. Placement is
not a detail; **placement is the whole enforcement story**, and §6 is about
finding out whether your loader has a place where a call can dominate every
evaluation path.

If it does not, you can still have the gate at install time, which is a real
and smaller claim, and you should describe it as the smaller claim in your
own docs as well as in ours.

### 5.3 The gate decides admission, not behaviour

A proven core proves its contract, not benevolence. An artefact that is
genuinely attested, genuinely intact, genuinely proven and genuinely contained
will be admitted, and may still be malicious. `admit` is not a safety claim
about what an extension *does*.

### 5.4 A host that lies to the gate gets an admit it did not earn

The gate decides from facts established outside it. If your code constructs
`verified` without hashing anything, you get `admit`. There is no way for the
gate to check, and pretending otherwise would be the same error in the other
direction.

The structural mitigation, if you want it, is the one we use: make the fact
tuple constructible by exactly one module, with unexported fields, so that no
other caller in your codebase *can* assert a fact it did not establish. In a
language without that, it is a review property, and you should say so.

### 5.5 A floor downgrade is detected, not defended

Someone with access to your configuration can set `floor_none`. The gate will
not second-guess your declared policy — a decider that overrode its host's
configuration would not be neutral, it would be a policy engine. What we do
instead is record the floor that was in force alongside the verdict, so a
downgrade leaves a trace and a later audit can re-decide every past load at
the higher floor. Do the same in your own log and you get the same property.

### 5.6 "Installation is gated" is not "loading is gated"

If you adopt this at an install-time policy hook only, you have bounded
installation. That is worth having. It is **not** the same claim as gating the
load, and the difference must be in writing before anyone uses the word
"proven" in public about the result. We would rather you adopt the smaller
thing accurately than the larger thing loosely.

### 5.7 The prebuilt binary is not reproducible across machines

We ship source, proof instructions and digests so you can rebuild and
re-prove. The **source** digests will match. The **binary** digests almost
certainly will not, because the artefact embeds a GNAT runtime and depends on
the exact toolchain that built it. We have not done the pinned-container work
that would make byte-identical builds possible, and we are not going to claim
it. The trust chain runs through the proof discharging on *your* machine and
the built binary agreeing with the complete truth table on *your* machine —
see `admission/REPROVE.md`, which says the same thing at greater length.

## 6. Worked example — a synchronous Node loader (OpenClaw)

This section is a worked example, not a proposal, and the observations below
are from a read of a local clone on 2026-08-31. **Re-verify every line number
against the version you are actually working with**; they move.

### Where the call would have to go

For a verdict to mean anything, the call must **dominate every path that
evaluates extension code**. In Node, evaluation happens at module load, so the
gate sits immediately before the module is imported, and must be the only
route there.

There is a funnel, and it is narrower than the documentation suggests. Plugin
module loading is obtained through:

- `getCachedPluginModuleLoader` — `src/plugins/plugin-module-loader-cache.ts:292`

with **13 production call sites across 12 files** in `src/plugins/`,
`src/channels/plugins/`, `src/secrets/`, `src/plugin-sdk/` and `src/cli/`
(plus one internal self-call from `getCachedPluginSourceModuleLoader` at
`:320`). The general plugin path reduces to a single expression at
`src/plugins/loader-module-runtime.ts:138-139`:

```ts
return (modulePath: string): unknown =>
    createLoaderForModule(modulePath)(toSafeImportPath(modulePath));
```

A gate wrapping the loader returned by `getCachedPluginModuleLoader` dominates
those 13 sites.

### Three things that constrain it — and one that breaks the "dominates" claim

**1. The loader is synchronous.** `type PluginModuleLoader = (target: string)
=> unknown` (`plugin-module-loader-cache.ts:20-21`, file-local, not exported).
No Promise anywhere. A gate there must decide synchronously, which rules out
an async subprocess call and is the concrete reason the C ABI exists rather
than being gold-plating.

**2. The cache is a decision cache.** `getCachedPluginModuleLoader` returns an
existing loader on a hit **before** creating anything:

```ts
const cacheEntry = resolvePluginModuleLoaderCacheEntry(params);
const cached = params.cache.get(cacheEntry.scopedCacheKey);
if (cached) {
  return cached;
}
```
(`:298-302`, returning before `createPluginModuleLoader` at `:306`.)

A gate placed at cache-miss would decide once and be reused thereafter. The
gate must therefore wrap the **returned closure's invocation**, so it fires on
every load — or the cache key must be bound to the same artefact identity the
facts were built from. This is a real trap and it is invisible from the docs.
(An aside worth knowing: the 128-entry LRU size is a *default parameter* to
`createPluginModuleLoaderCache`, and each of the ~11 production callers
creates its own cache. There is no single global one.)

**3. The funnel is not the only door.** `tryNativeRequireJavaScriptModule` is
defined in `src/plugins/native-module-require.ts:62` and has **three**
production call sites: `plugin-module-loader-cache.ts:276` (inside the wrapper
you would be gating), but also `src/plugins/runtime/runtime-plugin-boundary.ts:111`
and `src/plugin-sdk/channel-entry-contract.ts:419` — and **those two bypass the
loader cache entirely**. A wrapper on `getCachedPluginModuleLoader` therefore
does *not* dominate all native module evaluation. Any integration must cover
those two sites as well, or scope its claim to exclude them.

(One thing that looked like a bypass door and is not:
`plugin-metadata-snapshot.runtime.ts:54`'s bare `require(candidate)` resolves
only two hardcoded OpenClaw-relative snapshot modules through a file-local
helper. It cannot load third-party code.)

**4. And the part no placement fixes.** Native plugins run in-process at full
gateway trust. The project's own documentation
(`docs/plugins/architecture.md:425`) puts it plainly: *"a malicious native
plugin is equivalent to arbitrary code execution inside the OpenClaw
process."* Once one plugin has been evaluated it can monkey-patch the loader,
the cache, the wrapper, or the binding. This is §5.1, concretely.

### The cheaper thing first, and it needs no patch at all

`security.installPolicy` already runs a local command before install and takes
its result — implemented at `src/security/install-policy.ts:434`
(`runInstallPolicy`), called from
`src/plugins/install-security-scan.runtime.ts:764`. It execs an absolute,
path-checked command with a scrubbed environment, feeds the request as JSON on
stdin, and is **fail-closed**: non-zero exit, timeout, no-output timeout and
output-limit-exceeded all block (`:548-550` and neighbours), and only exit 0
has its stdout parsed as a verdict.

`extension_admission_front` is exactly that shape: argv in, word out, exit
0/1/2. So a host can adopt the gate at install time today with **no code
change and no C ABI** — a wrapper script that builds the six facts and shells
out. What that bounds is *installation*, not *loading*, and §5.6 applies.

### The honest summary

**The architecture permits the call, but not the guarantee.** Placement is
solvable for the cached-loader path; two native-require sites sit outside it;
and a decision taken inside a process where any admitted plugin can rewrite
the decider is a statement about supply chain, not about containment.

Run against this architecture as it stands, with containment answered
honestly, the gate refuses every native plugin — and it would be right to.
The routes to `admit` are: a per-plugin containment fact (the Docker sandbox
at `src/agents/sandbox/docker.ts` exists and fails closed, but nothing in
`src/plugins/` imports it — it is wired to the agent path, not the plugin
path), or plugin evaluation moved out of the gateway process, or a documented
acceptance that the guarantee is first-load-only. All three are architectural
decisions for the maintainers and none of them is ours to promise.

### Where to record the decision

`src/audit/` is the natural bind point: `audit-event-store.ts` writes
`actor_type` / `actor_id` and a validated `source_sequence`, so a load with no
admission record is visible afterwards. (Note the shape differs by layer: the
gateway-protocol wire schema uses a nested `actor: {type, id}`, while the
store uses flat `actorType` / `actorId`.) Detection after the fact is a
genuinely weaker claim than prevention — call it what it is.

## 7. Second sketch — a generic claw with a plugin API

For a host with a plugin API and an install step, and without Node's
synchronous-loader constraint. The shape is simpler and this is the one most
hosts should copy.

```
   discover / fetch artefact
        |
        v
   [ build the six facts ]        <-- the only interesting code you write
        |
        v
   exec extension_admission_front <facts>      (or claw_admit_decide)
        |
        +-- exit 0 + "admit" ------> load it, and RECORD the verdict,
        |                            the six facts, and the floor
        |
        +-- anything else ---------> do not load; surface the verdict word
                                     and its remedy to the operator;
                                     RECORD the refusal
```

Four rules, and only the first is subtle:

1. **Put the call where evaluation happens, not where discovery happens.**
   If your host can load a plugin by more than one route, either gate every
   route or say out loud which routes are gated. A gate on one of three doors
   is a gate on one of three doors.
2. **Build the facts from the bytes you are about to use.** Hash after you
   have the final copy in its final place, not before you copy it. Otherwise
   there is a window between the check and the load, and closing it is free
   if you get the ordering right and impossible if you do not.
3. **Only `exit 0` with the literal word `admit` admits.** Exit 1, exit 2, a
   signal, a timeout, a missing binary, an empty stdout, an unrecognised word,
   `admit` with anything else after it — every one of them is a refusal. This
   is the single most likely place for a well-meaning integrator to open the
   door, so make it a named test in your suite rather than a comment in your
   code.
4. **Record the verdict, the six facts, and the floor** in whatever ledger or
   audit log you already keep. Then a load can always be re-decided from its
   own record — at the same floor, or at a higher one during a later review —
   and a floor downgrade leaves a trace even though the gate did not stop it.

A worked instance of exactly this shape, in Go, over a real install path,
lives in ghillie's `internal/admit` (fact constructors, both install paths,
the fail-closed exit-code tests, and the ledger fields). It is AGPL and is not
part of this library; it is mentioned because a second implementation is
better evidence that the tuple is constructible than any amount of prose here.

## 8. What we ask in return

Nothing for us. One thing for the next person.

The library is **AGPL-3.0-or-later**. No attribution requirement beyond the
licence header, no dependency on anything of ours, no telemetry, no channel to
maintain, no support contract, no registration, no callback. Fork it, rename
it, rewrite it in your own language from the truth table, or ignore it
entirely.

The one condition is reciprocity on the gate itself: if you improve it, the
improvement stays readable by whoever is running a claw with it. Somebody who
lets software onto their machine on the strength of this gate ought to be able
to read the gate.

Where the condition applies:

| How you fit it | Licence reach |
|---|---|
| Exec the front binary (§2) — facts in, verdict and exit code out | Separate process. AGPL does not reach your claw. Close your source if you want. |
| Link `libkingklaw_admission` via `claw_admit.h` (§3) | The gate is in your program. AGPL comes with it. |
| Write your own gate from the truth table in §4 | The licence does not reach it at all. The table is a fact about admission, not our property. |

The exec route is the one we recommend on architectural grounds anyway — §6:
a gate sitting inside the process that any admitted plugin can rewrite is not
a gate — and it is also the route that asks least of you. Both routes are
documented in full; pick either.

Provenance rides in the licence header and in a one-line origin note inside
the files. That is the whole of the leash.
