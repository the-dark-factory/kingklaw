/* claw_admit.h — KingKlaw, admission member. The whole C surface, in one file.
 *
 * KingKlaw. He bows to none.
 *
 * SPDX-License-Identifier: MIT
 * Origin: forged and machine-checked with SPARK/GNATprove. Source and
 * re-proof instructions ship beside this header (see REPROVE.md). Nothing
 * here calls home, reads a clock, opens a file, allocates, or keeps state.
 *
 * Two symbols come out of the shared library. Everything else in this file
 * is a static inline you can read in a minute, or delete and rewrite.
 *
 *   claw_admit_decide_codes(...)  -> the verdict's ordinal, 0..8; 0 is admit
 *   claw_admit_status_codes(...)  -> 0 when admitted, 1 for every refusal
 *
 * Both take the six facts as ordinals in tuple order. Both are TOTAL: any
 * int at all is accepted, and every value the library does not recognise is
 * read as the LEAST PERMISSIVE value of its position. A garbled call
 * refuses; it can never admit. That direction is proved, not merely
 * intended.
 */

#ifndef CLAW_ADMIT_H
#define CLAW_ADMIT_H

#include <stdint.h>
#include <stddef.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- the six fact positions, in tuple order ---- */

enum { CLAW_FACT_OPERATOR = 0, CLAW_FACT_ORIGIN = 1, CLAW_FACT_INTEGRITY = 2,
       CLAW_FACT_PROOF = 3, CLAW_FACT_FLOOR = 4, CLAW_FACT_CONTAINMENT = 5,
       CLAW_FACT_COUNT = 6 };

/* 1. OPERATOR — did a human explicitly ask for THIS artefact, NOW? */
enum { CLAW_OPERATOR_REQUESTED = 0, CLAW_OPERATOR_ABSENT = 1 };

/* 2. ORIGIN — does an authority this host pinned vouch for identity->digest,
 *    and does that assertion still stand? */
enum { CLAW_ORIGIN_ATTESTED = 0, CLAW_ORIGIN_UNATTESTED = 1, CLAW_ORIGIN_REVOKED = 2 };

/* 3. INTEGRITY — do the bytes about to load hash to what was attested? */
enum { CLAW_INTEGRITY_VERIFIED = 0, CLAW_INTEGRITY_MISMATCH = 1, CLAW_INTEGRITY_UNCHECKED = 2 };

/* 4. PROOF — the artefact's honest proof rung. Absent is a valid answer. */
enum { CLAW_PROOF_REPROVED_HERE = 0, CLAW_PROOF_CARRIED = 1, CLAW_PROOF_ABSENT = 2 };

/* 5. FLOOR — the HOST's declared minimum rung for THIS load site. This is
 *    your policy, not the artefact's property. None is a valid answer. */
enum { CLAW_FLOOR_REPROVED_HERE = 0, CLAW_FLOOR_CARRIED = 1, CLAW_FLOOR_NONE = 2 };

/* 6. CONTAINMENT — will it run inside a boundary you control, or at your own
 *    process trust? A property of YOUR load plan, not of the artefact. */
enum { CLAW_CONTAINED = 0, CLAW_UNCONTAINED = 1 };

/* ---- the nine verdicts ---- */

enum {
    CLAW_ADMIT                       = 0,
    CLAW_REFUSE_OPERATOR_ABSENT      = 1,
    CLAW_REFUSE_ORIGIN_REVOKED       = 2,
    CLAW_REFUSE_ORIGIN_UNATTESTED    = 3,
    CLAW_REFUSE_INTEGRITY_MISMATCH   = 4,
    CLAW_REFUSE_INTEGRITY_UNCHECKED  = 5,
    CLAW_REFUSE_PROOF_ABSENT         = 6,
    CLAW_REFUSE_PROOF_NOT_REPROVED   = 7,
    CLAW_REFUSE_UNCONTAINED_UNPROVEN = 8,
    CLAW_VERDICT_COUNT               = 9
};

/* ---- the two exported symbols ---- */

int32_t claw_admit_decide_codes(int32_t operator_code, int32_t origin_code,
                                int32_t integrity_code, int32_t proof_code,
                                int32_t floor_code, int32_t containment_code);

int32_t claw_admit_status_codes(int32_t operator_code, int32_t origin_code,
                                int32_t integrity_code, int32_t proof_code,
                                int32_t floor_code, int32_t containment_code);

/* ---- verdict words ----
 *
 * The words are DATA, in this header, so you can read the mapping instead of
 * trusting it. They are the same nine words the command-line front prints and
 * the same nine the shipped TABLE.tsv names, and the shipped checker verifies
 * all three agree over the whole 324-row state space.
 */
static const char *const claw_admit_verdict_words[CLAW_VERDICT_COUNT] = {
    "admit",
    "refuse_operator_absent",
    "refuse_origin_revoked",
    "refuse_origin_unattested",
    "refuse_integrity_mismatch",
    "refuse_integrity_unchecked",
    "refuse_proof_absent",
    "refuse_proof_not_reproved",
    "refuse_uncontained_unproven"
};

/* claw_admit_verdict_word maps a verdict ordinal to its word. Out of range
 * yields "refuse_unknown_verdict" — a refusal word, never an admitting one,
 * so a code this header does not know still reads as a refusal to anything
 * doing string comparison. */
static inline const char *claw_admit_verdict_word(int32_t verdict)
{
    if (verdict < 0 || verdict >= CLAW_VERDICT_COUNT)
        return "refuse_unknown_verdict";
    return claw_admit_verdict_words[verdict];
}

/* claw_admit_decide — the convenience form, matching the command-line front's
 * contract exactly so that a host can move between the two without changing
 * how it reads the answer.
 *
 *   facts[6]     the six ordinals, in tuple order (see CLAW_FACT_* above)
 *   verdict_out  receives the NUL-terminated verdict word; may be NULL
 *   verdict_cap  the capacity of verdict_out in bytes
 *
 * returns 0  admitted        (verdict_out holds "admit")
 *         1  refused         (verdict_out holds the refusal word)
 *         2  malformed call  (facts was NULL, or the word did not fit;
 *                             verdict_out is left as an empty string)
 *
 * Note which way 2 falls: a caller that treats anything other than 0 as
 * "do not load" is correct under every outcome, including this one. That is
 * the only rule you have to get right.
 */
static inline int32_t claw_admit_decide(const int32_t facts[CLAW_FACT_COUNT],
                                        char *verdict_out, size_t verdict_cap)
{
    int32_t verdict;
    const char *word;
    size_t n;

    if (verdict_out != NULL && verdict_cap > 0)
        verdict_out[0] = '\0';
    if (facts == NULL)
        return 2;

    verdict = claw_admit_decide_codes(facts[CLAW_FACT_OPERATOR],
                                      facts[CLAW_FACT_ORIGIN],
                                      facts[CLAW_FACT_INTEGRITY],
                                      facts[CLAW_FACT_PROOF],
                                      facts[CLAW_FACT_FLOOR],
                                      facts[CLAW_FACT_CONTAINMENT]);
    word = claw_admit_verdict_word(verdict);

    if (verdict_out != NULL) {
        n = strlen(word);
        if (verdict_cap < n + 1)
            return 2;
        memcpy(verdict_out, word, n + 1);
    }
    return (verdict == CLAW_ADMIT) ? 0 : 1;
}

#ifdef __cplusplus
}
#endif

#endif /* CLAW_ADMIT_H */
