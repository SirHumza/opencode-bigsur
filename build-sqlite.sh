#!/bin/sh
# Build a modern libsqlite3.dylib for Big Sur.
#
# opencode's SQL uses RETURNING (SQLite >= 3.35) and jsonb (>= 3.45), but Big Sur's
# system SQLite is 3.32. Bun dlopens "libsqlite3.dylib" by leaf name, so a newer
# copy placed in $HOME/lib (on the default dyld fallback path) is preferred over
# /usr/lib. This compiles that copy.
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
SDK="${SDK:-/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk}"
VER="${SQLITE_VER:-3500400}"
YEAR="${SQLITE_YEAR:-2025}"
OUT="$HERE/dist"
TMP="$HERE/.sqlite-build"

[ -d "$SDK" ] || { echo "macOS 11 SDK not found: $SDK (set SDK=...)" >&2; exit 1; }
mkdir -p "$OUT" "$TMP"
cd "$TMP"

if [ ! -f "sqlite-amalgamation-$VER/sqlite3.c" ]; then
  echo "==> downloading SQLite $VER amalgamation"
  curl -sSL -o sqlite.zip "https://sqlite.org/$YEAR/sqlite-amalgamation-$VER.zip"
  unzip -o -q sqlite.zip
fi

echo "==> compiling libsqlite3.dylib (SQLite $VER)"
clang -dynamiclib -arch x86_64 -mmacosx-version-min=11.0 -isysroot "$SDK" \
  -install_name libsqlite3.dylib \
  -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE \
  -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_DBSTAT_VTAB \
  -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_LOAD_EXTENSION=1 -DSQLITE_THREADSAFE=1 \
  -DSQLITE_ENABLE_UNLOCK_NOTIFY \
  -o "$OUT/libsqlite3.dylib" "sqlite-amalgamation-$VER/sqlite3.c" -lpthread

echo "==> done: $OUT/libsqlite3.dylib"
