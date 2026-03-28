# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

An Android Library (AAR) that implements a VVC (H.266) software video decoder plugin for VCAT (Video Codec Acid Test). It wraps the [vvdec](https://github.com/fraunhoferhhi/vvdec) reference decoder via JNI and integrates with the host app through a plugin SPI based on ExoPlayer 2.x.

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

The build automatically fetches and compiles vvdec (default: v3.0.0) for both `arm64-v8a` and `armeabi-v7a`. Override the source with the `VVDEC_SRC` environment variable to point to a local clone.

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
