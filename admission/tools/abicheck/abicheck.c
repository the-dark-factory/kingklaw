/* abicheck — drive the shared library over the whole shipped truth table.
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 *
 * Reads TABLE.tsv (the 324-row table, token form) and checks that the C ABI
 * gives the same word and the same admit/refuse answer for every row as the
 * table says. Then it checks the fail-closed direction directly: for every
 * fact position, a code the library does not recognise must decide exactly as
 * the least permissive recognised code does.
 *
 * Build and run:  see ../../REPROVE.md
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "claw_admit.h"

struct token_map { const char *token; int32_t code; };

static const struct token_map operators[]  = { {"requested",0},{"absent",1},{NULL,0} };
static const struct token_map origins[]    = { {"attested",0},{"unattested",1},{"revoked",2},{NULL,0} };
static const struct token_map integrities[]= { {"verified",0},{"mismatch",1},{"unchecked",2},{NULL,0} };
static const struct token_map proofs[]     = { {"reproved",0},{"carried",1},{"absent",2},{NULL,0} };
static const struct token_map floors[]     = { {"floor_reproved",0},{"floor_carried",1},{"floor_none",2},{NULL,0} };
static const struct token_map containments[]={ {"contained",0},{"uncontained",1},{NULL,0} };

static const struct token_map *const positions[CLAW_FACT_COUNT] = {
    operators, origins, integrities, proofs, floors, containments
};

/* The least permissive code of each position — the value every unrecognised
 * code must decide as. Stated here independently of the library so that the
 * check is a check and not a tautology. */
static const int32_t fail_closed[CLAW_FACT_COUNT] = {
    CLAW_OPERATOR_ABSENT, CLAW_ORIGIN_UNATTESTED, CLAW_INTEGRITY_UNCHECKED,
    CLAW_PROOF_ABSENT, CLAW_FLOOR_REPROVED_HERE, CLAW_UNCONTAINED
};

static int code_of(const struct token_map *m, const char *tok, int32_t *out)
{
    for (; m->token != NULL; m++) {
        if (strcmp(m->token, tok) == 0) { *out = m->code; return 1; }
    }
    return 0;
}

int main(int argc, char **argv)
{
    const char *path = (argc > 1) ? argv[1] : "front/TABLE.tsv";
    FILE *f = fopen(path, "r");
    char line[512];
    int rows = 0, bad = 0;

    if (f == NULL) { fprintf(stderr, "abicheck: cannot open %s\n", path); return 2; }

    while (fgets(line, sizeof line, f) != NULL) {
        char argv_col[256], want_word[64];
        int want_exit;
        char *tok, *save;
        int32_t facts[CLAW_FACT_COUNT];
        int i, rc;
        char got_word[64];

        if (line[0] == '#' || line[0] == '\n') continue;
        if (sscanf(line, "%255[^\t]\t%63[^\t]\t%d", argv_col, want_word, &want_exit) != 3) {
            fprintf(stderr, "abicheck: unreadable row: %s", line);
            bad++; continue;
        }
        for (i = 0, tok = strtok_r(argv_col, " ", &save);
             i < CLAW_FACT_COUNT && tok != NULL;
             i++, tok = strtok_r(NULL, " ", &save)) {
            if (!code_of(positions[i], tok, &facts[i])) {
                fprintf(stderr, "abicheck: row names token %s, which position %d does not have\n", tok, i);
                bad++; facts[i] = -1;
            }
        }
        if (i != CLAW_FACT_COUNT) { fprintf(stderr, "abicheck: row has %d tokens, want 6\n", i); bad++; continue; }

        rc = claw_admit_decide(facts, got_word, sizeof got_word);
        if (rc != want_exit || strcmp(got_word, want_word) != 0) {
            fprintf(stderr, "MISMATCH %s: abi said %s (rc %d), table says %s (exit %d)\n",
                    line, got_word, rc, want_word, want_exit);
            bad++;
        }
        if (claw_admit_status_codes(facts[0],facts[1],facts[2],facts[3],facts[4],facts[5]) != want_exit) {
            fprintf(stderr, "MISMATCH (status) %s\n", line);
            bad++;
        }
        rows++;
    }
    fclose(f);
    printf("abi: checked %d rows against %s — %d mismatches\n", rows, path, bad);
    if (rows != 324) { fprintf(stderr, "abicheck: %d rows, want 324\n", rows); bad++; }

    /* FAIL-CLOSED DIRECTION, position by position.
     *
     * Each position gets its OWN base tuple, chosen so that two things are
     * true at once: the base ADMITS, and substituting that position's least
     * permissive value REFUSES. Both halves matter. A base that refuses
     * already proves nothing, and a base where the least permissive value
     * still admits (which is the case for FLOOR and CONTAINMENT under a
     * fully-proven artefact) would let a broken decode pass unnoticed.
     *
     * The property checked is the exact one: an unrecognised code must decide
     * precisely as the least permissive recognised code does — and therefore
     * must not admit.
     */
    {
        static const int32_t junk[] = { -1, 3, 4, 99, -2147483647 - 1, 2147483647 };
        static const int32_t base[CLAW_FACT_COUNT][CLAW_FACT_COUNT] = {
            /* OPERATOR    */ { CLAW_OPERATOR_REQUESTED, CLAW_ORIGIN_ATTESTED, CLAW_INTEGRITY_VERIFIED,
                                CLAW_PROOF_REPROVED_HERE, CLAW_FLOOR_NONE, CLAW_CONTAINED },
            /* ORIGIN      */ { CLAW_OPERATOR_REQUESTED, CLAW_ORIGIN_ATTESTED, CLAW_INTEGRITY_VERIFIED,
                                CLAW_PROOF_REPROVED_HERE, CLAW_FLOOR_NONE, CLAW_CONTAINED },
            /* INTEGRITY   */ { CLAW_OPERATOR_REQUESTED, CLAW_ORIGIN_ATTESTED, CLAW_INTEGRITY_VERIFIED,
                                CLAW_PROOF_REPROVED_HERE, CLAW_FLOOR_NONE, CLAW_CONTAINED },
            /* PROOF       */ { CLAW_OPERATOR_REQUESTED, CLAW_ORIGIN_ATTESTED, CLAW_INTEGRITY_VERIFIED,
                                CLAW_PROOF_REPROVED_HERE, CLAW_FLOOR_CARRIED, CLAW_CONTAINED },
            /* FLOOR       */ { CLAW_OPERATOR_REQUESTED, CLAW_ORIGIN_ATTESTED, CLAW_INTEGRITY_VERIFIED,
                                CLAW_PROOF_CARRIED, CLAW_FLOOR_CARRIED, CLAW_CONTAINED },
            /* CONTAINMENT */ { CLAW_OPERATOR_REQUESTED, CLAW_ORIGIN_ATTESTED, CLAW_INTEGRITY_VERIFIED,
                                CLAW_PROOF_ABSENT, CLAW_FLOOR_NONE, CLAW_CONTAINED }
        };
        int pos, j, failures = 0, checks = 0;

        for (pos = 0; pos < CLAW_FACT_COUNT; pos++) {
            int32_t safe[CLAW_FACT_COUNT], probe[CLAW_FACT_COUNT];
            int32_t want, got;

            if (claw_admit_decide(base[pos], NULL, 0) != 0) {
                fprintf(stderr, "abicheck: base tuple for position %d does not admit — "
                                "the probe would prove nothing\n", pos);
                failures++; continue;
            }
            memcpy(safe, base[pos], sizeof safe);
            safe[pos] = fail_closed[pos];
            want = claw_admit_decide_codes(safe[0],safe[1],safe[2],safe[3],safe[4],safe[5]);
            if (want == CLAW_ADMIT) {
                fprintf(stderr, "abicheck: base tuple for position %d still admits at its least "
                                "permissive value — the probe would prove nothing\n", pos);
                failures++; continue;
            }
            for (j = 0; j < (int)(sizeof junk / sizeof junk[0]); j++) {
                memcpy(probe, base[pos], sizeof probe);
                probe[pos] = junk[j];
                got = claw_admit_decide_codes(probe[0],probe[1],probe[2],probe[3],probe[4],probe[5]);
                checks++;
                if (got != want) {
                    fprintf(stderr, "FAIL-CLOSED BREACH position %d code %d: verdict %s, want %s\n",
                            pos, junk[j], claw_admit_verdict_word(got), claw_admit_verdict_word(want));
                    failures++;
                }
                if (got == CLAW_ADMIT) {
                    fprintf(stderr, "FAIL-CLOSED BREACH position %d code %d ADMITTED\n", pos, junk[j]);
                    failures++;
                }
            }
        }
        printf("abi: %d unrecognised-code probes across %d positions — %d breaches\n",
               checks, CLAW_FACT_COUNT, failures);
        bad += failures;
    }

    /* The convenience wrapper's own contract. */
    {
        char small[4];
        int32_t ok[CLAW_FACT_COUNT] = { 0,0,0,0,0,0 };
        int edge = 0;
        if (claw_admit_decide(NULL, small, sizeof small) != 2) { fprintf(stderr, "NULL facts did not give 2\n"); edge++; }
        if (small[0] != '\0') { fprintf(stderr, "NULL facts left rubbish in the buffer\n"); edge++; }
        if (claw_admit_decide(ok, small, sizeof small) != 2) { fprintf(stderr, "short buffer did not give 2\n"); edge++; }
        if (small[0] != '\0') { fprintf(stderr, "short buffer left a partial word\n"); edge++; }
        if (claw_admit_decide(ok, NULL, 0) != 0) { fprintf(stderr, "NULL buffer changed the verdict\n"); edge++; }
        printf("abi: wrapper edge cases — %d failures\n", edge);
        bad += edge;
    }

    if (bad > 0) { fprintf(stderr, "abicheck: %d problems\n", bad); return 1; }
    printf("abi: clean.\n");
    return 0;
}
