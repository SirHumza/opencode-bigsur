# opencode-bigsur

Run [opencode](https://github.com/anomalyco/opencode) (the official Bun-compiled
`opencode-ai` binary) on **macOS 11 Big Sur**.

The stock binary targets `minos 13.0`, so it refuses to launch on Big Sur. Two
things break once you get it loading:

1. **ICU.** The binary links `/usr/lib/libicucore.A.dylib`. Big Sur ships ICU 66,
   which is missing 11 symbols the binary needs (`ubrk_clone`, the `unumrf_*`
   range formatters, `udtitvfmt_formatCalendarToResult`,
   `uplrules_selectForRange`, `ucal_getTimeZoneOffsetFromLocal`).
2. **SQLite.** opencode's SQL uses `RETURNING` (SQLite >= 3.35) and `jsonb`
   (>= 3.45). Big Sur's system SQLite is 3.32, so session creation fails with
   `SQLiteError: near "returning": syntax error`. Bun `dlopen`s
   `libsqlite3.dylib` by leaf name, so a newer copy on the dyld fallback path
   wins.

This repo builds a small ICU shim and a modern SQLite dylib, rewrites the
binary to use them, and installs everything for the current user.

Verified on: macOS 11.7.10, MacBookAir6,2 (dual-core i5, 8 GB), opencode 1.19.3
(`--version`, `models`, chat, and tool calls all pass).

## Files

- `build.sh` – builds `libicu.dylib` (re-exports the SDK's ICU + defines the 11
  missing symbols) and patches/re-signs the opencode binary.
- `build-sqlite.sh` – downloads and compiles a modern `libsqlite3.dylib`.
- `install.sh` – installs the built artifacts for the current user.
- `ubrk_shim.c` – the ICU compatibility shim source.

## Usage

Run the build on a Mac with an **Xcode/CLT macOS 11 SDK** (a newer Mac is fine;
the target machine does not need a compiler):

```sh
# 1. get the raw darwin-x64 binary (postinstall won't run it, which is good,
#    since it can't execute on a pre-13 machine either)
npm pack opencode-darwin-x64@1.19.3
tar xzf opencode-darwin-x64-1.19.3.tgz

# 2. build (pass the raw binary; default is your global opencode-ai install)
./build.sh package/bin/opencode
./build-sqlite.sh
```

Copy `dist/` to the Big Sur machine and install:

```sh
./install.sh          # on the Big Sur Mac; writes to ~/opencode and ~/lib
```

Then open a new Terminal and run `opencode`.

If the SDK isn't at the default path, override it:

```sh
SDK=/path/to/MacOSX11.sdk ./build.sh /path/to/opencode
```

## Caveats

- **Do not run `opencode upgrade` on the Big Sur build.** It replaces the patched
  binary with the official `minos 13` build, which will not launch. To update,
  re-run `build.sh` against the new `opencode-darwin-x64` package.
- The `install.sh` PATH line is added to `~/.zshrc`.
- This targets the **terminal TUI**. The Electron desktop app will not run on
  Big Sur (same `minos` floor, and it would be very slow on 2013-2014 Intel
  Macs anyway).
