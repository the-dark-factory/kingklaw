--  Copyright (C) 2026 The Dark Factory Ltd
--  SPDX-License-Identifier: AGPL-3.0-or-later
--  Forged and machine-checked by The Dark Factory. This file is the
--  vendored copy of an IMMUTABLE wu round output. This comment block is
--  the only difference from it; nothing below this line is altered.
--  Reproduce with scripts/stamp-licence.sh in the ada-factory repo.
--  Unstamped source sha256: 27c835a1ae2a005a71b6a4b286c011dd49e4c10e2a505afec3ebdd30fbdc31d0
--
-- Extension_Admission_Pkg -- whether one extension artefact may be admitted to
-- load, or is refused with its reason named. A neutral admission decider: it
-- names no bundle, no plugin, no manifest field, no file layout and no
-- language, so any host that can establish six facts can use it.
--
-- PURPOSE. Deciding what may load is the one decision a host cannot afford to
-- get wrong, and it is the decision that is usually not made anywhere in
-- particular -- it emerges from a handful of functions that each return no
-- error. This core makes that decision a named thing with a proved contract.
-- The properties a host needs are theorems here: nothing loads that a human
-- did not ask for, nothing loads whose origin no pinned authority vouches for,
-- nothing loads whose bytes were not checked against what was attested,
-- nothing loads below the proof rung the host declared for that load site,
-- unproven code never loads at the host's own process trust inside no
-- boundary, and every non-admitting input refuses with its reason named.
--
-- SCOPE BOUNDARY (state in a header comment): this core DECIDES one admission
-- only. It verifies no signature, hashes no bytes, reads no clock, opens no
-- file, holds no state and loads nothing. Whether a human really asked,
-- whether the attesting authority really attested and still stands, whether
-- the bytes really hash to what was attested, what proof rung the artefact
-- really reached, what rung this load site really demands, and whether the
-- loader really contains anything are all established by the surrounding
-- untrusted host and handed in as the enumerations below. What is proved here
-- is what FOLLOWS once those facts are established -- and, equally, that
-- nothing else follows.
--
-- DESIGN DECISION (state in a header comment). Six facts in, one verdict out,
-- and the evaluation ORDER is part of the design: a refusal names the FIRST
-- failing fact in the fixed order operator, origin, integrity, proof, floor,
-- containment. The cheap, universally-actionable refusals fire before the
-- architectural one, so a host with no containment story at all still gets
-- real value: a forged, altered or revoked artefact is refused long before the
-- containment question is reached. The proof requirement is a FACT HANDED IN
-- by the host, not a rule baked into this theorem -- a host may declare no
-- floor at all and still have operator, origin and integrity decided for it,
-- and may raise its floor later without a new core. Exactly one rule cannot be
-- configured away: unproven code, at the host's own process trust, inside no
-- boundary, is refused whatever the floor says. There is no third verdict and
-- no default path: every one of the 324 inputs is either the admitting
-- combination or a named refusal.

package Extension_Admission_Pkg with SPARK_Mode => On, Pure is

   type Operator_State_Type is (Operator_Requested, Operator_Absent);
   -- whether a human explicitly asked for THIS artefact, NOW:
   -- Operator_Requested means a fresh human act initiated this load;
   -- Operator_Absent means it was initiated by something else -- a schedule, an
   -- auto-update, a standing grant, a peer.

   type Origin_State_Type is (Origin_Attested, Origin_Unattested, Origin_Revoked);
   -- whether an authority this host has pinned asserts the binding from this
   -- artefact's identity to this digest, and whether that assertion still
   -- stands: Origin_Attested means it is asserted and stands; Origin_Unattested
   -- covers BOTH no known authority and a known authority silent about this
   -- artefact; Origin_Revoked means the authority has withdrawn it.

   type Integrity_State_Type is (Integrity_Verified, Integrity_Mismatch, Integrity_Unchecked);
   -- whether the bytes about to load hash to the digest the authority recorded:
   -- Integrity_Verified means they were hashed and match; Integrity_Mismatch
   -- means they were hashed and differ, so the delivery is altered;
   -- Integrity_Unchecked means nobody hashed them at all.

   type Proof_State_Type is (Proof_Reproved_Here, Proof_Carried, Proof_Absent);
   -- the artefact's honest proof rung: Proof_Reproved_Here means its proofs
   -- were re-derived on this machine; Proof_Carried means it ships proofs that
   -- were read but not re-run here; Proof_Absent means it carries none.

   type Proof_Floor_Type is (Floor_Reproved_Here, Floor_Carried, Floor_None);
   -- the HOST's declared minimum rung for THIS load site, which is the host's
   -- policy and not the artefact's property: Floor_Reproved_Here demands proofs
   -- re-derived here; Floor_Carried demands at least carried proofs;
   -- Floor_None demands no proof at all and is an honest, valid answer.

   type Containment_State_Type is (Contained, Uncontained);
   -- whether the artefact will run inside a boundary the host controls, or at
   -- the host's own process trust. It is a property of the LOADER'S OWN PLAN,
   -- not of the artefact.

   type Admission_Verdict_Type is (Admit, Refuse_Operator_Absent, Refuse_Origin_Revoked, Refuse_Origin_Unattested, Refuse_Integrity_Mismatch, Refuse_Integrity_Unchecked, Refuse_Proof_Absent, Refuse_Proof_Not_Reproved, Refuse_Uncontained_Unproven);
   -- the decision: Admit permits the load; every other value is a refusal
   -- carrying its reason. Refuse_Origin_Unattested covers BOTH "no authority
   -- known" and "known authority, silent about this artefact" -- a verdict word
   -- need not recover its state, but a state must determine its verdict.
   -- Refuse_Proof_Absent and Refuse_Proof_Not_Reproved are deliberately two
   -- words and not one: "carries no proof at all" and "carries proofs but no
   -- prover ran here" have different remedies.

   function Meets_Floor (Proof : Proof_State_Type; Floor : Proof_Floor_Type) return Boolean is
     ((if Floor = Floor_None then True
       elsif Floor = Floor_Carried then Proof /= Proof_Absent
       else Proof = Proof_Reproved_Here))
     with Post =>
       (if Floor = Floor_None then Meets_Floor'Result) and
       (if Floor = Floor_Carried then (Meets_Floor'Result = (Proof /= Proof_Absent))) and
       (if Floor = Floor_Reproved_Here then (Meets_Floor'Result = (Proof = Proof_Reproved_Here)));

   function Is_Admissible (Operator : Operator_State_Type; Origin : Origin_State_Type; Integrity : Integrity_State_Type; Proof : Proof_State_Type; Floor : Proof_Floor_Type; Containment : Containment_State_Type) return Boolean is
     (Operator = Operator_Requested and Origin = Origin_Attested and Integrity = Integrity_Verified and Meets_Floor (Proof, Floor) and (Containment = Contained or else Proof /= Proof_Absent));

   function Decide (Operator : Operator_State_Type; Origin : Origin_State_Type; Integrity : Integrity_State_Type; Proof : Proof_State_Type; Floor : Proof_Floor_Type; Containment : Containment_State_Type) return Admission_Verdict_Type is
     (if Operator = Operator_Absent then Refuse_Operator_Absent
      elsif Origin = Origin_Revoked then Refuse_Origin_Revoked
      elsif Origin = Origin_Unattested then Refuse_Origin_Unattested
      elsif Integrity = Integrity_Mismatch then Refuse_Integrity_Mismatch
      elsif Integrity = Integrity_Unchecked then Refuse_Integrity_Unchecked
      elsif not Meets_Floor (Proof, Floor) and Proof = Proof_Absent then Refuse_Proof_Absent
      elsif not Meets_Floor (Proof, Floor) then Refuse_Proof_Not_Reproved
      elsif Containment = Uncontained and Proof = Proof_Absent then Refuse_Uncontained_Unproven
      else Admit)
     with Post =>
       (Decide'Result = Admit) = Is_Admissible (Operator, Origin, Integrity, Proof, Floor, Containment) and
       (if Operator = Operator_Absent then Decide'Result = Refuse_Operator_Absent) and
       (if Origin = Origin_Revoked then Decide'Result /= Admit) and
       (if Origin = Origin_Unattested then Decide'Result /= Admit) and
       (if Integrity /= Integrity_Verified then Decide'Result /= Admit) and
       (if not Meets_Floor (Proof, Floor) then Decide'Result /= Admit) and
       (if (Containment = Uncontained and Proof = Proof_Absent) then Decide'Result /= Admit) and
       (if Decide'Result = Admit then (Operator = Operator_Requested and Origin = Origin_Attested and Integrity = Integrity_Verified and Meets_Floor (Proof, Floor) and (Containment = Contained or else Proof /= Proof_Absent))) and
       (if (Operator = Operator_Requested and Origin = Origin_Revoked) then Decide'Result = Refuse_Origin_Revoked) and
       (if (Operator = Operator_Requested and Origin = Origin_Unattested) then Decide'Result = Refuse_Origin_Unattested) and
       (if (Operator = Operator_Requested and Origin = Origin_Attested and Integrity = Integrity_Mismatch) then Decide'Result = Refuse_Integrity_Mismatch) and
       (if (Operator = Operator_Requested and Origin = Origin_Attested and Integrity = Integrity_Unchecked) then Decide'Result = Refuse_Integrity_Unchecked) and
       (if (Operator = Operator_Requested and Origin = Origin_Attested and Integrity = Integrity_Verified and Proof = Proof_Absent and Floor /= Floor_None) then Decide'Result = Refuse_Proof_Absent) and
       (if (Operator = Operator_Requested and Origin = Origin_Attested and Integrity = Integrity_Verified and Proof = Proof_Carried and Floor = Floor_Reproved_Here) then Decide'Result = Refuse_Proof_Not_Reproved) and
       (if (Operator = Operator_Requested and Origin = Origin_Attested and Integrity = Integrity_Verified and Proof = Proof_Absent and Floor = Floor_None and Containment = Uncontained) then Decide'Result = Refuse_Uncontained_Unproven);

end Extension_Admission_Pkg;
