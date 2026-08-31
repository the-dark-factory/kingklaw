-- Extension_Admission_Marshal_Pkg -- the C calling convention, and nothing else.
-- It is the entire surface a host outside Ada ever touches. It converts integers to integers,
-- calls the proven Extension_Admission_Abi_Pkg, and returns. It holds no state, allocates nothing,
-- performs no I/O, and has no branch of its own: every branch is inside the proven packages behind it.
--
-- PURPOSE (state in a header comment). A synchronous loader cannot spawn a process, so it needs
-- the admission decision through an in-process call. This package is that call. It is deliberately
-- the smallest thing that can be written: two entry points, each one conversion in and one conversion out.
-- It carries no buffer, no pointer, no length and no string, so the entire class of memory faults at a C boundary
-- has nowhere to occur here. The verdict WORD is not produced here at all -- the caller maps the returned code
-- to a word through the table that ships beside this library, so that the mapping is data the caller can read
-- rather than code the caller must trust.
--
-- SCOPE BOUNDARY (state in a header comment): this package decides nothing and recognises nothing.
-- The fail-closed direction of every unrecognised code is decided and proved in Extension_Admission_Abi_Pkg;
-- the admission itself is decided and proved in Extension_Admission_Pkg. What is here is a name and a calling convention.

with Interfaces.C;
with Extension_Admission_Abi_Pkg;

package Extension_Admission_Marshal_Pkg with SPARK_Mode => On is

   function Claw_Admit_Decide_Codes (Operator_Code    : Interfaces.C.int;
                                    Origin_Code      : Interfaces.C.int;
                                    Integrity_Code   : Interfaces.C.int;
                                    Proof_Code       : Interfaces.C.int;
                                    Floor_Code       : Interfaces.C.int;
                                    Containment_Code : Interfaces.C.int) return Interfaces.C.int is
     (Interfaces.C.int (Extension_Admission_Abi_Pkg.Decide_Code (Integer (Operator_Code),
                                                                 Integer (Origin_Code),
                                                                 Integer (Integrity_Code),
                                                                 Integer (Proof_Code),
                                                                 Integer (Floor_Code),
                                                                 Integer (Containment_Code))))
     with Export => True, Convention => C, External_Name => "claw_admit_decide_codes",
          Post => (Claw_Admit_Decide_Codes'Result in 0 .. 8);

   function Claw_Admit_Status_Codes (Operator_Code    : Interfaces.C.int;
                                    Origin_Code      : Interfaces.C.int;
                                    Integrity_Code   : Interfaces.C.int;
                                    Proof_Code       : Interfaces.C.int;
                                    Floor_Code       : Interfaces.C.int;
                                    Containment_Code : Interfaces.C.int) return Interfaces.C.int is
     (Interfaces.C.int (Extension_Admission_Abi_Pkg.Status_Of_Code (Integer (Operator_Code),
                                                                   Integer (Origin_Code),
                                                                   Integer (Integrity_Code),
                                                                   Integer (Proof_Code),
                                                                   Integer (Floor_Code),
                                                                   Integer (Containment_Code))))
     with Export => True, Convention => C, External_Name => "claw_admit_status_codes",
          Post => (Claw_Admit_Status_Codes'Result in 0 .. 1);

end Extension_Admission_Marshal_Pkg;
