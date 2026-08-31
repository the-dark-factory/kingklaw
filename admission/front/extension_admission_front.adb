--  Copyright (C) 2026 The Dark Factory Ltd
--  SPDX-License-Identifier: AGPL-3.0-or-later
--  Forged and machine-checked by The Dark Factory. This file is the
--  vendored copy of an IMMUTABLE wu round output. This comment block is
--  the only difference from it; nothing below this line is altered.
--  Reproduce with scripts/stamp-licence.sh in the ada-factory repo.
--  Unstamped source sha256: f0312c893c5da9648b05c1800ecbe4dc57ccef249480b3f06b48482a26f1427b
--
-- extension_admission_front.adb
-- the executable front for the proven admission decider.

with Ada.Command_Line;
with Ada.Text_IO;
with Extension_Admission_Pkg;

use type Extension_Admission_Pkg.Operator_State_Type;
use type Extension_Admission_Pkg.Origin_State_Type;
use type Extension_Admission_Pkg.Integrity_State_Type;
use type Extension_Admission_Pkg.Proof_State_Type;
use type Extension_Admission_Pkg.Proof_Floor_Type;
use type Extension_Admission_Pkg.Containment_State_Type;

procedure extension_admission_front is
   use Ada.Command_Line;
   use Ada.Text_IO;
   use Extension_Admission_Pkg;

   Operator  : Operator_State_Type;
   Origin    : Origin_State_Type;
   Integrity : Integrity_State_Type;
   Proof     : Proof_State_Type;
   Floor     : Proof_Floor_Type;
   Containment : Containment_State_Type;
   Verdict   : Admission_Verdict_Type;
begin
   if Argument_Count /= 6 then
      Put_Line(Standard_Error, "Invalid argument count.");
      Set_Exit_Status(2);
      return;
   end if;

   -- OPERATOR
   if Argument(1) = "requested" then
      Operator := Operator_Requested;
   elsif Argument(1) = "absent" then
      Operator := Operator_Absent;
   else
      Put_Line(Standard_Error, "Invalid token in position 1.");
      Set_Exit_Status(2);
      return;
   end if;

   -- ORIGIN
   if Argument(2) = "attested" then
      Origin := Origin_Attested;
   elsif Argument(2) = "unattested" then
      Origin := Origin_Unattested;
   elsif Argument(2) = "revoked" then
      Origin := Origin_Revoked;
   else
      Put_Line(Standard_Error, "Invalid token in position 2.");
      Set_Exit_Status(2);
      return;
   end if;

   -- INTEGRITY
   if Argument(3) = "verified" then
      Integrity := Integrity_Verified;
   elsif Argument(3) = "mismatch" then
      Integrity := Integrity_Mismatch;
   elsif Argument(3) = "unchecked" then
      Integrity := Integrity_Unchecked;
   else
      Put_Line(Standard_Error, "Invalid token in position 3.");
      Set_Exit_Status(2);
      return;
   end if;

   -- PROOF
   if Argument(4) = "reproved" then
      Proof := Proof_Reproved_Here;
   elsif Argument(4) = "carried" then
      Proof := Proof_Carried;
   elsif Argument(4) = "absent" then
      Proof := Proof_Absent;
   else
      Put_Line(Standard_Error, "Invalid token in position 4.");
      Set_Exit_Status(2);
      return;
   end if;

   -- FLOOR
   if Argument(5) = "floor_reproved" then
      Floor := Floor_Reproved_Here;
   elsif Argument(5) = "floor_carried" then
      Floor := Floor_Carried;
   elsif Argument(5) = "floor_none" then
      Floor := Floor_None;
   else
      Put_Line(Standard_Error, "Invalid token in position 5.");
      Set_Exit_Status(2);
      return;
   end if;

   -- CONTAINMENT
   if Argument(6) = "contained" then
      Containment := Contained;
   elsif Argument(6) = "uncontained" then
      Containment := Uncontained;
   else
      Put_Line(Standard_Error, "Invalid token in position 6.");
      Set_Exit_Status(2);
      return;
   end if;

   Verdict := Decide(Operator, Origin, Integrity, Proof, Floor, Containment);

   case Verdict is
      when Admit =>
         Put_Line("admit");
         Set_Exit_Status(0);
      when Refuse_Operator_Absent =>
         Put_Line("refuse_operator_absent");
         Set_Exit_Status(1);
      when Refuse_Origin_Revoked =>
         Put_Line("refuse_origin_revoked");
         Set_Exit_Status(1);
      when Refuse_Origin_Unattested =>
         Put_Line("refuse_origin_unattested");
         Set_Exit_Status(1);
      when Refuse_Integrity_Mismatch =>
         Put_Line("refuse_integrity_mismatch");
         Set_Exit_Status(1);
      when Refuse_Integrity_Unchecked =>
         Put_Line("refuse_integrity_unchecked");
         Set_Exit_Status(1);
      when Refuse_Proof_Absent =>
         Put_Line("refuse_proof_absent");
         Set_Exit_Status(1);
      when Refuse_Proof_Not_Reproved =>
         Put_Line("refuse_proof_not_reproved");
         Set_Exit_Status(1);
      when Refuse_Uncontained_Unproven =>
         Put_Line("refuse_uncontained_unproven");
         Set_Exit_Status(1);
   end case;

end extension_admission_front;
