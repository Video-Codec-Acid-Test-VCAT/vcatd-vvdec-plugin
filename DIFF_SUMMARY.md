# DIFF_SUMMARY

Running summary of notable changes to `vcatd-vvdec-plugin`, newest first.

---

## 2026-10-01 — Bump vvdec `v3.0.0` → `v3.2.0`

- Default `vvdecRef` in `app/build.gradle` now tracks **vvdec 3.2.0** (upstream's latest stable,
  released 2026-07-28). Override still available via `-PvvdecRef=` or `VVDEC_SRC`.
- **No JNI changes needed.** Header diff between the tags is additive only: `vvdecAccessUnit`
  gained `userData` + reserved slots, `vvdecSeqInfo.reserved_1` split into
  `maxLatencyIncreasePlus1` / `maxNumReorderPics`, and `vvdecPicAttributes.reservedPtr_1` became
  `userData`. `vvdec_jni.cc` touches none of those fields and only calls stable entry points
  (`vvdec_decode`, `vvdec_frame_unref`, `vvdec_accessUnit_*`, `vvdec_flush`,
  `vvdec_decoder_open`/`_close`).
- 3.2.0 generates `vvdec.h` from `vvdec.h.in` at configure time instead of shipping it as a
  static file. Harmless here — `app/src/main/cpp/CMakeLists.txt` includes from the per-ABI
  install prefix, not the source tree.
- **Fixed a latent bug in `fetchVvdec`** that the bump exposed: on an existing shallow clone,
  `git fetch --depth 1 origin <tag>` populates `FETCH_HEAD` but never creates the tag locally, so
  the follow-up `git checkout -f <ref>` failed with `pathspec 'v3.2.0' did not match any
  file(s) known to git`. Now checks out `FETCH_HEAD` detached (works for tags, branches and
  SHAs alike) plus `git clean -xfd` to drop stale output from the previous ref. Any future ref
  bump would have hit the same wall.
- Verified: `assembleRelease` + `dist` green, vvdec rebuilt for both ABIs, checked-out commit
  `649f0b2` matches `refs/tags/v3.2.0`, generated `version.h` reports `VVDEC_VERSION "3.2.0"`,
  dist AAR carries the injected `classes.dex` and both `libvcat_vvdec_jni.so` variants.
- Not addressed (pre-existing, reproduced on clean `main`): `./gradlew test` fails to compile —
  `VvcVideoCfgParserTest` imports `com.roncatech.libvcat.decoder` from the `compileOnly` api dep,
  which isn't on the unit-test classpath.

---

## 2026-08-07 — Rename `Mp4DecoderPlugin` → `Mp4ParserExtension`

- `VcatVvcdecPlugin` now implements `VcatDecoder, Mp4ParserExtension` (the MP4 `stsd` container-
  parser interface was renamed in the api). Pure rename — no behavior change.
- api dep bumped `1.0.2 → 1.0.3`. Builds against api `1.0.3`.

---

## 2026-08-05 — Migrate to the `VcatDecoder` SPI

- `VcatVvcdecPlugin` now implements **`VcatDecoder` + `Mp4DecoderPlugin`** (was the deprecated
  `VcatDecoderPlugin` + `NonStdDecoderStsdParser`).
- VVC uses a **non-standard MP4 sample entry** (`vvc1` / `vvcC`), so the plugin advertises itself
  as its own MP4 `stsd` parser via `getSupportedContainerParsers()` → `[this]`;
  `sampleEntry4ccCode()` / `codecConfiguration4ccCode()` / `parseStsd()` now come from
  `Mp4DecoderPlugin`. (This is the case dav1d didn't exercise — AV1's `av01` is standard.)
- Dropped `getSupportedProfiles()` and the legacy `mimeType()` accessor; codec MIME is the
  decoder's `getMimeType()` (and `VideoConfiguration.mimeType`, still set by `VvcVideoCfgParser`).
- Reports plugin API **`0.1.0`** (inherited `VcatDecoder` default; legacy decoders report
  `0.0.1`).
- `compileOnly` / `testImplementation` api dep bumped `1.0.1 → 1.0.2` (Maven Local).
- Verified on-device: `vcat.vvdec` registers and its native lib loads; the host info-overlay
  shows `Plugin API: 0.1.0` when vvdec is the selected VVC decoder.

## Initial — VVC/H.266 (vvdec) decoder plugin

- External VVC decoder plugin wrapping Fraunhofer vvdec via JNI. Package
  `com.roncatech.libvcat.vvdec`, native lib `libvcat_vvdec_jni.so`, MIME `video/vvc`, id
  `vcat.vvdec`. vvdec built from source; `dist` task injects `classes.dex` for the host's
  `DexClassLoader`. GPL-3.0-or-later; vvdec is Clear BSD (see `LICENSE`).
