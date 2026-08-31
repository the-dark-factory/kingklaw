--  Copyright (C) 2026 The Dark Factory Ltd
--  SPDX-License-Identifier: AGPL-3.0-or-later
--  Forged and machine-checked by The Dark Factory. This file is the
--  vendored copy of an IMMUTABLE wu round output. This comment block is
--  the only difference from it; nothing below this line is altered.
--  Reproduce with scripts/stamp-licence.sh in the ada-factory repo.
--  Unstamped source sha256: 61bc7072b278076bf52a38594620f2bcc1a53433444bf08bb413d45b97cd564e
--
-- Extension_Admission_Abi_Pkg -- the integer boundary of the proven admission
-- decider. It decodes six UNTRUSTED integers into Extension_Admission_Pkg's
-- enumerations, asks that package the admission question, and encodes the
-- answer back to an integer. It recognises and it marshals. It decides
-- NOTHING: every verdict is the withed package's verdict, unaltered.
--
-- PURPOSE (state in a header comment). A host that cannot spawn a process --
-- because its loader is synchronous, or because it is not a shell -- needs the
-- same decision in-process, through a C call. That call carries integers, not
-- enumerations, so something must turn one into the other. Doing that
-- conversion in unproven C or unproven Ada would put the fail-closed direction
-- of every unrecognised code outside the proof, which is exactly the part that
-- must not be outside it. So the conversion is proved here, and the only thing
-- left outside is a name and a calling convention.
--
-- DESIGN DECISION -- WHICH WAY GARBAGE FALLS (state in a header comment). An
-- integer arriving over a C boundary may be anything at all: a truncated read,
-- a field never written, a sign extension, a caller compiled against a
-- different vocabulary. So the decode must choose a direction for values it
-- does not recognise, and the choice is load-bearing. Every unrecognised code
-- decodes to the LEAST PERMISSIVE value of its enumeration, never to the value
-- that helps a load through:
--   an unrecognised operator code is Operator_Absent, not Operator_Requested;
--   an unrecognised origin code is Origin_Unattested, so nothing is vouched
--     for by accident;
--   an unrecognised integrity code is Integrity_Unchecked, so no unhashed byte
--     is ever reported as verified;
--   an unrecognised proof code is Proof_Absent, so no proof is credited that
--     was not stated;
--   an unrecognised FLOOR code is Floor_Reproved_Here -- the STRICTEST floor,
--     not the weakest, because the floor is the host's DEMAND and a garbled
--     demand must be read as the highest one, never as "no requirement";
--   an unrecognised containment code is Uncontained, so no boundary is assumed
--     that was not stated.
-- The reason to write it this way round: Admit is the one outcome that must be
-- unreachable by accident. A decode that resolved garbage towards the
-- permissive value would let a corrupted call authorise a load. Falling to the
-- least permissive value means a garbled call yields a REFUSAL, which is the
-- harmless failure, and can never yield Admit.
--
-- SCOPE BOUNDARY (state in a header comment): this package adds no decision.
-- It performs no I/O, holds no state, reads no clock and allocates nothing.
-- Everything it proves is about the direction of a decode and the faithfulness
-- of an encode.

with Extension_Admission_Pkg;
use type Extension_Admission_Pkg.Operator_State_Type;
use type Extension_Admission_Pkg.Origin_State_Type;
use type Extension_Admission_Pkg.Integrity_State_Type;
use type Extension_Admission_Pkg.Proof_State_Type;
use type Extension_Admission_Pkg.Proof_Floor_Type;
use type Extension_Admission_Pkg.Containment_State_Type;
use type Extension_Admission_Pkg.Admission_Verdict_Type;

package Extension_Admission_Abi_Pkg with SPARK_Mode => On, Pure is

   function Operator_Of_Code (Code : Integer) return Extension_Admission_Pkg.Operator_State_Type is
     (if Code = 0 then Extension_Admission_Pkg.Operator_Requested else Extension_Admission_Pkg.Operator_Absent)
     with Post =>
       (if Code = 0 then Operator_Of_Code'Result = Extension_Admission_Pkg.Operator_Requested) and
       (if Code /= 0 then Operator_Of_Code'Result = Extension_Admission_Pkg.Operator_Absent);

   function Origin_Of_Code (Code : Integer) return Extension_Admission_Pkg.Origin_State_Type is
     (if Code = 0 then Extension_Admission_Pkg.Origin_Attested elsif Code = 2 then Extension_Admission_Pkg.Origin_Revoked else Extension_Admission_Pkg.Origin_Unattested)
     with Post =>
       (if Code = 0 then Origin_Of_Code'Result = Extension_Admission_Pkg.Origin_Attested) and
       (if Code = 2 then Origin_Of_Code'Result = Extension_Admission_Pkg.Origin_Revoked) and
       (if (Code /= 0 and Code /= 2) then Origin_Of_Code'Result = Extension_Admission_Pkg.Origin_Unattested);

   function Integrity_Of_Code (Code : Integer) return Extension_Admission_Pkg.Integrity_State_Type is
     (if Code = 0 then Extension_Admission_Pkg.Integrity_Verified elsif Code = 1 then Extension_Admission_Pkg.Integrity_Mismatch else Extension_Admission_Pkg.Integrity_Unchecked)
     with Post =>
       (if Code = 0 then Integrity_Of_Code'Result = Extension_Admission_Pkg.Integrity_Verified) and
       (if Code = 1 then Integrity_Of_Code'Result = Extension_Admission_Pkg.Integrity_Mismatch) and
       (if (Code /= 0 and Code /= 1) then Integrity_Of_Code'Result = Extension_Admission_Pkg.Integrity_Unchecked);

   function Proof_Of_Code (Code : Integer) return Extension_Admission_Pkg.Proof_State_Type is
     (if Code = 0 then Extension_Admission_Pkg.Proof_Reproved_Here elsif Code = 1 then Extension_Admission_Pkg.Proof_Carried else Extension_Admission_Pkg.Proof_Absent)
     with Post =>
       (if Code = 0 then Proof_Of_Code'Result = Extension_Admission_Pkg.Proof_Reproved_Here) and
       (if Code = 1 then Proof_Of_Code'Result = Extension_Admission_Pkg.Proof_Carried) and
       (if (Code /= 0 and Code /= 1) then Proof_Of_Code'Result = Extension_Admission_Pkg.Proof_Absent);

   function Floor_Of_Code (Code : Integer) return Extension_Admission_Pkg.Proof_Floor_Type is
     (if Code = 1 then Extension_Admission_Pkg.Floor_Carried elsif Code = 2 then Extension_Admission_Pkg.Floor_None else Extension_Admission_Pkg.Floor_Reproved_Here)
     with Post =>
       (if Code = 1 then Floor_Of_Code'Result = Extension_Admission_Pkg.Floor_Carried) and
       (if Code = 2 then Floor_Of_Code'Result = Extension_Admission_Pkg.Floor_None) and
       (if (Code /= 1 and Code /= 2) then Floor_Of_Code'Result = Extension_Admission_Pkg.Floor_Reproved_Here);

   function Containment_Of_Code (Code : Integer) return Extension_Admission_Pkg.Containment_State_Type is
     (if Code = 0 then Extension_Admission_Pkg.Contained else Extension_Admission_Pkg.Uncontained)
     with Post =>
       (if Code = 0 then Containment_Of_Code'Result = Extension_Admission_Pkg.Contained) and
       (if Code /= 0 then Containment_Of_Code'Result = Extension_Admission_Pkg.Uncontained);

   function Code_Of_Verdict (Verdict : Extension_Admission_Pkg.Admission_Verdict_Type) return Integer is
     (if Verdict = Extension_Admission_Pkg.Refuse_Operator_Absent then 1 elsif Verdict = Extension_Admission_Pkg.Refuse_Origin_Revoked then 2 elsif Verdict = Extension_Admission_Pkg.Refuse_Origin_Unattested then 3 elsif Verdict = Extension_Admission_Pkg.Refuse_Integrity_Mismatch then 4 elsif Verdict = Extension_Admission_Pkg.Refuse_Integrity_Unchecked then 5 elsif Verdict = Extension_Admission_Pkg.Refuse_Proof_Absent then 6 elsif Verdict = Extension_Admission_Pkg.Refuse_Proof_Not_Reproved then 7 elsif Verdict = Extension_Admission_Pkg.Refuse_Uncontained_Unproven then 8 else 0)
     with Post =>
       (Code_Of_Verdict'Result in 0 .. 8) and
       ((Code_Of_Verdict'Result = 0) = (Verdict = Extension_Admission_Pkg.Admit));

   function Decide_Code (Operator_Code : Integer; Origin_Code : Integer; Integrity_Code : Integer; Proof_Code : Integer; Floor_Code : Integer; Containment_Code : Integer) return Integer is
     (Code_Of_Verdict (Extension_Admission_Pkg.Decide (Operator_Of_Code (Operator_Code), Origin_Of_Code (Origin_Code), Integrity_Of_Code (Integrity_Code), Proof_Of_Code (Proof_Code), Floor_Of_Code (Floor_Code), Containment_Of_Code (Containment_Code))))
     with Post =>
       (Decide_Code'Result in 0 .. 8) and
       ((Decide_Code'Result = 0) = Extension_Admission_Pkg.Is_Admissible (Operator_Of_Code (Operator_Code), Origin_Of_Code (Origin_Code), Integrity_Of_Code (Integrity_Code), Proof_Of_Code (Proof_Code), Floor_Of_Code (Floor_Code), Containment_Of_Code (Containment_Code)));

   function Status_Of_Code (Operator_Code : Integer; Origin_Code : Integer; Integrity_Code : Integer; Proof_Code : Integer; Floor_Code : Integer; Containment_Code : Integer) return Integer is
     (if Decide_Code (Operator_Code, Origin_Code, Integrity_Code, Proof_Code, Floor_Code, Containment_Code) = 0 then 0 else 1)
     with Post =>
       (Status_Of_Code'Result in 0 .. 1) and
       ((Status_Of_Code'Result = 0) = (Decide_Code (Operator_Code, Origin_Code, Integrity_Code, Proof_Code, Floor_Code, Containment_Code) = 0));

end Extension_Admission_Abi_Pkg;
