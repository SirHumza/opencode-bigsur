#!/bin/sh
# Install the Big Sur opencode build for the current user.
# Run on the Big Sur Mac after building (build.sh + build-sqlite.sh) on a newer Mac,
# or after copying dist/ here.
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/dist"
[ -f "$SRC/opencode" ] || { echo "missing $SRC/opencode (run ./build.sh first)" >&2; exit 1; }
[ -f "$SRC/libicu.dylib" ] || { echo "missing $SRC/libicu.dylib" >&2; exit 1; }

mkdir -p "$HOME/opencode" "$HOME/lib"
cp "$SRC/opencode" "$HOME/opencode/opencode"
cp "$SRC/libicu.dylib" "$HOME/opencode/libicu.dylib"
chmod +x "$HOME/opencode/opencode"
if [ -f "$SRC/libsqlite3.dylib" ]; then
  cp "$SRC/libsqlite3.dylib" "$HOME/lib/libsqlite3.dylib"
else
  echo "warning: dist/libsqlite3.dylib missing; Big Sur session creation will fail" >&2
fi

RC="$HOME/.zshrc"
if ! grep -q 'opencode (Big Sur build)' "$RC" 2>/dev/null; then
  printf '\n# opencode (Big Sur build)\nexport PATH="$HOME/opencode:$PATH"\n' >> "$RC"
  echo "added $HOME/opencode to PATH in $RC"
fi

echo "installed. Open a new Terminal and run: opencode"
echo "  binary:  $HOME/opencode/opencode"
echo "  icu:     $HOME/opencode/libicu.dylib"
echo "  sqlite:  $HOME/lib/libsqlite3.dylib"
