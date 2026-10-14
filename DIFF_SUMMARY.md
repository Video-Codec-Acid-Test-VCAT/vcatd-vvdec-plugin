# DIFF_SUMMARY

Running summary of notable changes to `vcatd-vvdec-plugin`, newest first.

---

## 2026-10-14 — Send the container's parameter sets to vvdec; VVC-only-in-vvcC played black

`VvcVideoCfgParser` extracts VPS/SPS/PPS from the `vvcC` box into `Format.initializationData`
with Annex B start codes attached. **Nothing ever sent them to vvdec.** Grepping the plugin for
`initializationData` returned exactly one hit: the line that stores it.

So the decoder only ever worked on streams that happen to repeat their parameter sets in-band.
A stream carrying them solely in `vvcC` produced slices with no active SPS: `vvdec_decode`
returned `VVDEC_ERR_DEC_INPUT` (-4) for every access unit, zero pictures came out, and the
surface stayed black with no error dialog — the decoder was alive and rejecting everything.

Found with a JNI diagnostic that dumps the head of the first three access units:

```
AU[0] size=69734 startsAnnexB=YES head: 00 00 00 01 00 a1 88  00 00 00 01 00 89 20 ...
                                                   type 20 = AUD      type 17 = PREFIX_APS
```

Annex B conversion was fine; the parameter sets simply were not there. After the fix:

```
AU[0] size=254   type 15 = SPS
AU[1] size=18    type 16 = PPS
AU[2] size=69734 the sample
```

`sendCsdIfNeeded()` queues each buffer as its own access unit ahead of the first sample, which
keeps the sample's own timestamp intact, once per format. It re-arms on `setInputFormat()` and
after a flush, since a flush drops decoder state including the parameter sets.

**What this was not.** Ruled out before finding it: the file (ffmpeg decodes it, and so do vvdec
3.0.0 and 3.2.0 built from source at 200+ fps), the vvdec version, the `vvcC` parsing (simulated
against both files' real records — both yield 1920x1080 with correct SPS/PPS arrays), and the
missing `colr` box.

### Also: the two vvdec plugins were indistinguishable in logcat

Both defined `LOG_TAG "vvdec_jni"`, so there was no way to tell which produced a line — and
`vcat-vvdec-3.0.0` turned out to be the one running while the 3.2 plugin was being debugged.
The 3.0 fork now logs as `vvdec30_jni`.

---

## 2026-10-13 — Never refuse input; the 16-packet cap ended runs mid-stall

`nativeQueueInput` returned `-EAGAIN` once 16 packets were queued, and `VvdecDecoder` turns any
non-zero rc into a `VvdecDecoderException` — which surfaces as a playback error and **ends the
run**.

That is not back-pressure. Sixteen packets is about half a second of video, ExoPlayer buffers
50 s ahead, and a full queue only means the decoder is briefly behind, which is recoverable. The
cap is also worst-placed: in steady state the backlog never approaches 16, but a skip-to-keyframe
spiral — measured at 139 skips in 300 s with throughput down to 8.5 fps — builds a backlog by
definition. So it fired precisely during the episodes worth measuring, and is the likely cause of
the vvdec 3.0.0 battery run that terminated early with no explanation.

Input is never refused now. The backlog is unbounded and logged once past a soft threshold of 64
packets; ExoPlayer's own 50 s buffer bounds it upstream. `nativeHasCapacity` always returns true.

The same defect was fixed in `vcatd-dav1d-plugin`, where it was worse — that plugin discarded the
declined packet instead of raising, losing bitstream silently.

---

## 2026-10-06 — Log how late the renderer thinks it is at the skip threshold

Diagnostic only; no behaviour change. `shouldDropBuffersToKeyframe` now logs `earlyUs` when it
fires, rate-limited to one line a second.

CPH2625 runs report rows discarding 1,554–7,495 frames to a keyframe in a single interval, while
every row covering the body of a clip reports **zero** drops. Those cannot both describe a
decoder falling behind. Reaching this threshold at −500 ms means first spending a long time past
`shouldDropOutputBuffer`'s −50 ms, which would leave a trail of small drops; there is none across
102 body rows. And 6,000 frames is 200 seconds of lateness, which would require sustained
half-rate decode for minutes — again leaving a trail that is absent.

So the suspicion is a discontinuity in the timestamps `earlyUs` is computed against rather than a
slow decoder, and the renderer is the only place that can be observed directly. Telemetry records
how many frames a skip discarded but never how late the renderer believed it was when it asked,
and that is the number in dispute.

Pairs with the host-side columns added the same day (`video.frames_rendered`,
`video.dropped_to_keyframe_events`), which bound the same question arithmetically: one skip can
only discard what is in the sample queue, and `DefaultLoadControl` caps that at 50 s.

---

## 2026-10-04 — Stop force-rendering late frames; drop them to hold the native frame rate

`VvdecVideoRenderer` overrode `shouldForceRenderOutputBuffer` to return `earlyUs <= 0` — render
whenever a frame is due or already late. `DecoderVideoRenderer.processOutputBuffer` evaluates that
check *before* the drop checks, so every late frame was rendered and the
`shouldDropOutputBuffer` branch below it was unreachable. Playback advanced at whatever rate the
decoder managed instead of dropping frames to stay on the clock.

That inverts the benchmark: a decoder that cannot keep up stretches the timeline and is rewarded
with a longer battery run. Measured on CPH2625 against the 604.8 s / 29.97 fps 1080p VVC stream,
where realtime is 5.95 loops/hour:

| build | loops/hour | realtime | `frames_dropped` | battery |
|---|---|---|---|---|
| vvdec 3.0.0 | 3.8 | 0.64× | 0 | 8.00 h |
| vvdec 3.2.0 | 5.8 | 0.97× | 0 | 6.57 h |

3.0.0 was playing in slow motion while reporting no drops, which made the older build look like
the more efficient one. It was simply doing less work per hour.

The override is removed. The inherited thresholds now apply: drop a frame at `earlyUs < -50 ms`,
drop to the next keyframe at `earlyUs < -500 ms` — what a player does. Playback holds the
content's frame rate, and a decoder that falls behind sheds frames and says so, which is what
makes `frames_dropped` and the battery number mean anything.

The same override was removed from the dav1d and dav2d plugins, so all five decoders are now
measured on the same terms.

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
