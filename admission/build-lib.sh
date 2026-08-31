#!/usr/bin/env bash
#  Build KingKlaw's admission member: the shared library that carries the C
#  entry points, the command-line front, and the checker that keeps the C ABI
#  honest against the shipped table.
#
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  This script BUILDS. It proves nothing. Proving is a separate command —
#  `gnatprove -P src/proof.gpr --level=2` — and REPROVE.md is the instruction
#  sheet. The two are deliberately kept apart so neither can be mistaken for
#  the other.
#
#  A host adopting this library needs NO Ada toolchain: it needs the files in
#  lib/ and the header in include/. The toolchain is needed only by whoever
#  wants to rebuild or re-prove the artefact themselves — which is the whole
#  reason the source ships beside the binary.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

[ -x "$HOME/.alire/bin/gprbuild" ] && export PATH="$HOME/.alire/bin:$PATH"
command -v gprbuild >/dev/null || { echo "build-lib: no gprbuild on PATH" >&2; exit 1; }

case "$(uname -s)" in
   Darwin)
      SO=dylib
      export LIBRARY_PATH="$(xcrun --show-sdk-path)/usr/lib"
      RT_GLOB='libgnat-*.dylib'; GCC_GLOB='libgcc_s.1.1.dylib' ;;
   Linux)
      SO=so
      RT_GLOB='libgnat-*.so*';   GCC_GLOB='libgcc_s.so.1' ;;
   *)  echo "build-lib: unsupported platform $(uname -s)" >&2; exit 1 ;;
esac

rm -rf obj lib

#  ENCAPSULATED FIRST. An encapsulated standalone library carries the Ada
#  runtime inside itself, so the artefact a host copies has no Ada dependency
#  at all. GNAT supports it on Linux and refuses it on macOS, so this is a
#  try-then-fall-back rather than a choice.
ENCAPSULATED=no
if gprbuild -p -P kingklaw_admission.gpr -XKINGKLAW_STANDALONE=encapsulated >/dev/null 2>&1; then
   ENCAPSULATED=yes
   echo "built lib/libkingklaw_admission.$SO — encapsulated: the Ada runtime is inside it"
else
   rm -rf obj lib
   gprbuild -p -P kingklaw_admission.gpr -XKINGKLAW_STANDALONE=standard >/dev/null
   echo "built lib/libkingklaw_admission.$SO — this platform has no encapsulated"
   echo "  standalone libraries, so the runtime closure is vendored beside it:"
   ADALIB="$(dirname "$(command -v gnatls 2>/dev/null || command -v gprbuild)")"
   for glob in "$RT_GLOB" "$GCC_GLOB"; do
      found="$(find "$HOME/.alire" "$HOME/.local/share/alire/toolchains" "$ADALIB/.." /usr/lib \
                    -name "$glob" 2>/dev/null | head -1)"
      if [ -n "$found" ]; then
         cp -f "$found" lib/ && echo "    vendored $(basename "$found")"
      else
         echo "    NOTE: $glob not found — a host without a matching GNAT runtime"
         echo "          will fail at load time. Say so; do not ship it quietly."
      fi
   done
fi

echo "building the command-line front"
( cd front && gprbuild -q -p -P edge.gpr )

echo "building the C ABI checker"
cc -O2 -I include -o tools/abicheck/abicheck tools/abicheck/abicheck.c \
   -L lib -lkingklaw_admission -Wl,-rpath,"$HERE/lib"

echo
echo "CHECK BOTH — neither artefact is finished until both are clean:"
echo "  go run ./tools/tablegen -out front/TABLE.tsv -check front/extension_admission_front"
echo "  ./tools/abicheck/abicheck front/TABLE.tsv"
