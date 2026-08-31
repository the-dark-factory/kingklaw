// Command tablegen writes the complete 324-row truth table for
// extension_admission_front and checks the built binary against every row.
//
// The point of this program is that it is an INDEPENDENT second
// implementation. The verdict chain below is transcribed from the design
// document's prose (DESIGN_proven_extension_admission_2026-08-31.md, §2),
// not from the Ada; the Ada was written by the factory planner from the same
// prose. Agreement across all 324 rows is therefore evidence about the prose
// being implemented twice the same way, which is the only thing a truth
// table can honestly be evidence about.
//
// Usage:
//
//	go run ./tablegen -out TABLE.tsv                 # write the table
//	go run ./tablegen -out TABLE.tsv -check ./front  # write it and check the binary
package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strings"
)

// The six fact positions, in tuple order, with their exact tokens.
var (
	operators    = []string{"requested", "absent"}
	origins      = []string{"attested", "unattested", "revoked"}
	integrities  = []string{"verified", "mismatch", "unchecked"}
	proofs       = []string{"reproved", "carried", "absent"}
	floors       = []string{"floor_reproved", "floor_carried", "floor_none"}
	containments = []string{"contained", "uncontained"}
)

// meetsFloor is the design's named helper: the artefact's rung reaches the
// rung this load site demands.
func meetsFloor(proof, floor string) bool {
	switch floor {
	case "floor_none":
		return true
	case "floor_carried":
		return proof != "absent"
	case "floor_reproved":
		return proof == "reproved"
	}
	return false
}

// decide is the design's evaluation order, which IS the definition.
func decide(operator, origin, integrity, proof, floor, containment string) string {
	switch {
	case operator == "absent":
		return "refuse_operator_absent"
	case origin == "revoked":
		return "refuse_origin_revoked"
	case origin == "unattested":
		return "refuse_origin_unattested"
	case integrity == "mismatch":
		return "refuse_integrity_mismatch"
	case integrity == "unchecked":
		return "refuse_integrity_unchecked"
	case !meetsFloor(proof, floor) && proof == "absent":
		return "refuse_proof_absent"
	case !meetsFloor(proof, floor):
		return "refuse_proof_not_reproved"
	case containment == "uncontained" && proof == "absent":
		return "refuse_uncontained_unproven"
	default:
		return "admit"
	}
}

// exitFor is the front's exit-status contract: 0 admits, 1 refuses.
func exitFor(verdict string) int {
	if verdict == "admit" {
		return 0
	}
	return 1
}

// row is one truth-table line.
type row struct {
	argv    []string
	verdict string
	exit    int
}

// table enumerates the whole state space in a fixed, reproducible order.
func table() []row {
	var rows []row
	for _, op := range operators {
		for _, or := range origins {
			for _, in := range integrities {
				for _, pr := range proofs {
					for _, fl := range floors {
						for _, co := range containments {
							v := decide(op, or, in, pr, fl, co)
							rows = append(rows, row{
								argv:    []string{op, or, in, pr, fl, co},
								verdict: v,
								exit:    exitFor(v),
							})
						}
					}
				}
			}
		}
	}
	return rows
}

// malformed is the fail-closed edge set: every one of these must exit 2 with
// nothing at all on standard output. Adversarial pass #6 and #7 of the design
// are tested here as first-class cases, not left as a code comment.
var malformed = [][]string{
	{},
	{"requested"},
	{"requested", "attested", "verified", "reproved", "floor_none"},
	{"requested", "attested", "verified", "reproved", "floor_none", "contained", "extra"},
	{"REQUESTED", "attested", "verified", "reproved", "floor_none", "contained"},
	{"yes", "attested", "verified", "reproved", "floor_none", "contained"},
	{"requested", "trusted", "verified", "reproved", "floor_none", "contained"},
	{"requested", "attested", "ok", "reproved", "floor_none", "contained"},
	{"requested", "attested", "verified", "proved", "floor_none", "contained"},
	{"requested", "attested", "verified", "reproved", "none", "contained"},
	{"requested", "attested", "verified", "reproved", "floor_none", "sandboxed"},
	// Argument transposition: PROOF and FLOOR swapped. The floor_ prefix
	// makes this invalid in BOTH positions rather than a silently different
	// question.
	{"requested", "attested", "verified", "floor_none", "reproved", "contained"},
	{"requested", "attested", "verified", "floor_carried", "carried", "contained"},
	{"", "attested", "verified", "reproved", "floor_none", "contained"},
	{"requested", "attested", "verified", "reproved", "floor_none", ""},
}

func main() {
	out := flag.String("out", "TABLE.tsv", "path to write the truth table")
	check := flag.String("check", "", "path of the built front to check every row against")
	flag.Parse()

	rows := table()
	if len(rows) != 324 {
		fmt.Fprintf(os.Stderr, "tablegen: enumerated %d rows, want 324 — the state space is wrong\n", len(rows))
		os.Exit(1)
	}

	var b strings.Builder
	b.WriteString("# extension_admission_front — the complete truth table.\n")
	b.WriteString("# All 324 rows of the state space (2 x 3 x 3 x 3 x 3 x 2), not a sample.\n")
	b.WriteString("# Columns: <argv>\\t<expected stdout>\\t<expected exit status>\n")
	b.WriteString("# argv order: OPERATOR ORIGIN INTEGRITY PROOF FLOOR CONTAINMENT\n")
	for _, r := range rows {
		fmt.Fprintf(&b, "%s\t%s\t%d\n", strings.Join(r.argv, " "), r.verdict, r.exit)
	}
	if err := os.WriteFile(*out, []byte(b.String()), 0o644); err != nil {
		fmt.Fprintf(os.Stderr, "tablegen: writing %s: %v\n", *out, err)
		os.Exit(1)
	}

	counts := map[string]int{}
	for _, r := range rows {
		counts[r.verdict]++
	}
	names := make([]string, 0, len(counts))
	for k := range counts {
		names = append(names, k)
	}
	sort.Strings(names)
	fmt.Printf("wrote %s — %d rows, %d distinct verdicts\n", *out, len(rows), len(counts))
	for _, n := range names {
		fmt.Printf("  %-28s %3d\n", n, counts[n])
	}
	if len(counts) != 9 {
		fmt.Fprintf(os.Stderr, "tablegen: %d distinct verdicts, want 9 — a verdict with an empty preimage is a lie about the design\n", len(counts))
		os.Exit(1)
	}

	if *check == "" {
		return
	}

	bad := 0
	for _, r := range rows {
		cmd := exec.Command(*check, r.argv...)
		stdout, _ := cmd.Output()
		got := strings.TrimSpace(string(stdout))
		gotExit := cmd.ProcessState.ExitCode()
		if got != r.verdict || gotExit != r.exit {
			bad++
			fmt.Fprintf(os.Stderr, "MISMATCH %v: binary said %q exit %d, table says %q exit %d\n",
				r.argv, got, gotExit, r.verdict, r.exit)
		}
	}
	fmt.Printf("checked %d/%d rows against %s — %d mismatches\n", len(rows)-bad, len(rows), *check, bad)

	badEdge := 0
	for _, argv := range malformed {
		cmd := exec.Command(*check, argv...)
		stdout, _ := cmd.Output()
		got := strings.TrimSpace(string(stdout))
		gotExit := cmd.ProcessState.ExitCode()
		if gotExit != 2 || got != "" {
			badEdge++
			fmt.Fprintf(os.Stderr, "MALFORMED-CASE FAIL %v: exit %d stdout %q — want exit 2 and empty stdout\n", argv, gotExit, got)
		}
	}
	fmt.Printf("checked %d/%d malformed inputs — %d failures (want exit 2, empty stdout)\n",
		len(malformed)-badEdge, len(malformed), badEdge)

	if bad > 0 || badEdge > 0 {
		os.Exit(1)
	}
}
