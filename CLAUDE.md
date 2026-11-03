# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A VVC (H.266) software video decoder plugin for VCAT (Video Codec Acid Test), wrapping the [vvdec](https://github.com/fraunhoferhhi/vvdec) reference decoder. **One project, two outputs:**

- **Android:** an AAR, via JNI and a plugin SPI based on ExoPlayer 2.x (`app/`, Gradle).
- **iOS:** an `.xcframework` holding one self-describing dynamic library for vcat-d-ios (`ios/` + `native/`, `ios/build_xcframework.sh`).

`plugin.json` is the single source of truth for the id (`vcat.vvdec`), MIME type and the pinned vvdec ref. Gradle reads it, and so does the iOS script. Gradle only includes `app/`; the iOS script never touches Gradle and needs no Android SDK. Keep platform-specific code in `app/` (Android) or `ios/` + `native/` (iOS). vvdec 3.0 (`vcatd-vvdec-30-plugin`) is Android-only and gets no iOS output.

The AAR is published to Maven Local: `com.roncatech.vcat:vcatd-vvdec-plugin:0.0.1`

## Build Commands

```bash
# Build release AAR + inject classes.dex → build/outputs/dist/vcatd-vvdec-plugin.aar
./gradlew dist

# Build and publish to Maven Local (~/.m2/repository/com/roncatech/vcat/vcatd-vvdec-plugin/)
./gradlew publishPlugin

# Run unit tests
./gradlew test

# Run a single test class
./gradlew test --tests "com.roncatech.libvcat.vvdec.VvcVideoCfgParserTest"

# Standard assemble
./gradlew assembleRelease
```

The build automatically fetches and compiles vvdec at the `plugin.json` pin (v3.2.0) for both `arm64-v8a` and `armeabi-v7a`. Override the source with the `VVDEC_SRC` environment variable to point to a local clone.

iOS:

```bash
ios/build_xcframework.sh   # → build/dist/vcatd-vvdec-plugin.xcframework (needs Xcode, cmake, ninja,
                           #   and vcat-d-ios next to this repo for plugin-api/vcat_decoder_plugin.h)
```

The iOS plugin is `native/vcat_plugin_vvdec.c` (vcat-d-ios plugin C ABI v2, exporting only `vcat_plugin_entry`), linked with `clang++` against vvdec into `vcatd_vvdec.framework`. The manifest generated from `plugin.json` sits in `__TEXT,__vcat_manifest` and is also returned by `manifest_json()`; read it with `segedit -extract` (`otool -s` prints target-endian words). It must keep the decode-loop rules of `vvdec_jni.cc`: TRY_AGAIN = consumed (never resend), never refuse input, drop a rejected AU and continue, cts passthrough, `vvdec_flush` only after `end_of_stream` (a NULL AU mid-stream is an error). `decoder_name` = `vcat-vvdec-` + `vvdec_get_version()`, untruncated, same as Android. The CMake toolchain is `ios/cmake/ios.toolchain.cmake` (moved here from vcat-d-ios).

The `dist` task post-processes the AAR: it extracts `classes.jar`, runs D8 to produce `classes.dex` (minApi 29), then repacks the AAR with the DEX injected — required for plugin loading by the host app.

## Architecture

### Plugin Layer
- **`VcatVvcdecPlugin`** — SPI entry point. Implements `VcatDecoderPlugin` and `NonStdDecoderStsdParser`. Declares MIME type `video/vvc`, handles `vvcC` stsd box parsing, and returns a `VvdecProvider`.
- **`VvdecProvider`** — Factory for `VvdecVideoRenderer`. Checks JNI library availability before advertising support.

### Decoder Layer
- **`VvdecVideoRenderer`** — Extends ExoPlayer's `DecoderVideoRenderer`. Manages the decoder lifecycle, surface blitting (YV12 → ANativeWindow), format negotiation, and late-frame dropping/seeking policy (drop if >50ms late, seek keyframe if ~0.5s behind).
- **`VvdecDecoder`** — Extends ExoPlayer's `SimpleDecoder`. Orchestrates the input queue → native decode → output drain loop. Reinitializes the native decoder on format change. Manages flush/reset.
- **`VvdecOutputBuffer`** — Extends `VideoDecoderOutputBuffer`. Carries a `nativePic` handle (pointer to `vvdecFrame*`) that is passed back to native for rendering or release.

### JNI Bridge
- **`NativeVvdec`** — Declares all `native` methods.
- **`VvdecLibrary`** — Thread-safe `System.loadLibrary("vcat_vvdec_jni")` wrapper.
- **`app/src/main/cpp/vvdec_jni.cc`** — Full JNI implementation. Key structs:
  - `NativeCtx` — holds `vvdecDecoder*`, a pending input deque (`InputNode*`), a ready frame deque (`vvdecFrame*`), and a mutex-guarded `ANativeWindow*`.
  - `InputNode` — wraps `vvdecAccessUnit` with PTS.
  - `PictureHolder` — wraps `vvdecFrame*` for JNI callback return.

### Parsing Utilities
- **`VvcVideoCfgParser`** — Parses the `vvcC` MP4 configuration box; extracts VPS/SPS/PPS NALUs and calls into `VvcNalUnitUtil` to decode width/height.
- **`VvcNalUnitUtil`** — Parses H.266 SPS NAL units (profile, level, chroma format, bit depth, resolution).

## Key Design Decisions

- **ExoPlayer 2.x (2.19.1)** — Uses the legacy ExoPlayer 2 API, not Media3. Buffer flag constants come from ExoPlayer 2.x.
- **DEX injection** — The `dist` task injects a `classes.dex` into the AAR so the plugin classloader can load it at runtime without compilation.
- **Compile-only dependencies** — `decoder-plugin-api` and `exoplayer-core` are `compileOnly`; they must be provided by the host app at runtime.
- **JNI mirrors dav1d pattern** — The native layer follows the same idiom used by the dav1d plugin for consistency across VCAT plugins.
- **Thread-safe surface binding** — `nativeSetSurface` holds a mutex when swapping `ANativeWindow*` to avoid races with the render thread.
