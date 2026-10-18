#!/bin/sh
# Produce a macOS 11 (Big Sur) compatible opencode from an existing x64 binary.
#
# Big Sur's system ICU (libicucore, ICU 66) is missing 11 symbols that the
# Bun-compiled opencode runtime links against (ubrk_clone, unumrf_*,
# udtitvfmt_formatCalendarToResult, uplrules_selectForRange,
# ucal_getTimeZoneOffsetFromLocal). This builds a small shim that supplies them
# and rewrites the binary's ICU dependency to load it, so opencode runs on 10.16/11.
#
# Usage: ./build.sh [path-to-opencode-binary]
#   default source: $(npm root -g)/opencode-ai/bin/opencode.exe
#   override SDK:   SDK=/path/to/MacOSX11.sdk ./build.sh
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
SDK="${SDK:-/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk}"
SRC="${1:-$(npm root -g 2>/dev/null)/opencode-ai/bin/opencode.exe}"
OUT="$HERE/dist"

[ -f "$SRC" ] || { echo "source binary not found: $SRC" >&2; exit 1; }
[ -d "$SDK" ] || { echo "macOS 11 SDK not found: $SDK (set SDK=...)" >&2; exit 1; }

mkdir -p "$OUT"

echo "==> building ICU compatibility shim"
clang -dynamiclib -arch x86_64 -mmacosx-version-min=11.0 -isysroot "$SDK" \
  -install_name "@loader_path/libicu.dylib" \
  -o "$OUT/libicu.dylib" "$HERE/ubrk_shim.c" \
  -Wl,-reexport_library,"$SDK/usr/lib/libicucore.A.tbd"

echo "==> patching opencode binary"
cp "$SRC" "$OUT/opencode"
chmod +x "$OUT/opencode"
codesign --remove-signature "$OUT/opencode" 2>/dev/null || true
install_name_tool -change /usr/lib/libicucore.A.dylib @loader_path/libicu.dylib "$OUT/opencode"
codesign --force --sign - "$OUT/opencode"

echo "==> done: $OUT/opencode + $OUT/libicu.dylib"
echo "    Next: ./build-sqlite.sh  (modern SQLite; Big Sur's 3.32 lacks RETURNING/jsonb)"
echo "    Then: ./install.sh"
