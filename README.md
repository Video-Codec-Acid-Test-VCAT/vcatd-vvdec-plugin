# vcatd-vvdec-plugin

VVC/H.266 software decoder plugin for [VCAT (Video Codec Acid Test)](https://github.com/Video-Codec-Acid-Test-VCAT/vcat-d).

Wraps [vvdec](https://github.com/fraunhoferhhi/vvdec) (Fraunhofer H.266 decoder) as a VCAT decoder
plugin. Declares MIME type `video/vvc`.

One project, two outputs: an **Android `.aar`** for vcat (Gradle, `app/`) and an **iOS
`.xcframework`** (one dynamic library) for vcat-d-ios (`ios/` + `native/`). Both are built from
the same `plugin.json` (id, MIME type, pinned vvdec source), and each build ignores the other
platform's directories. Build instructions: [Android](#android), [iOS](#ios).

| | Android | iOS |
|---|---|---|
| Build | `./gradlew dist` | `ios/build_xcframework.sh` |
| Output | `app/build/outputs/dist/vcatd-vvdec-plugin.aar` | `build/dist/vcatd-vvdec-plugin.xcframework` |
| Drop into | `vcat/decoder-plugins/` | `vcat-d-ios/decoder-plugins/` |
| Decoder glue | JNI (`app/src/main/cpp/vvdec_jni.cc`) | C ABI glue (`native/vcat_plugin_vvdec.c`) |
| Form | `.aar`, loaded at app startup | dynamic library, embedded at app build, loaded at app launch |

## Plugin version

The plugin's own version (**0.1.0**) lives in `plugin.json` (`version`), separate from the
decoder library's version. Gradle uses it as the library/Maven version. The iOS build writes it
into the framework's `CFBundleShortVersionString` / `CFBundleVersion` and into the embedded
manifest. Bump it there once, and both platforms carry the same number.

## Pinned vvdec source

vvdec is **built from source**, not bundled. Both builds clone it at the release pinned in
`plugin.json` (**v3.2.0**) and build a static `libvvdec.a` per target. Nothing prebuilt is
carried in the repo. Since VCAT measures decoder performance, moving the pin is a deliberate
act: edit `source.ref` in `plugin.json`, which changes both platforms. Each build also takes a
one-off override (below).

The separate `vcatd-vvdec-30-plugin` (vvdec 3.0.0) is an Android-only local build and has no iOS
counterpart.

## Android

### Prerequisites

- JDK 17+
- Android SDK with:
  - NDK **27.0.12077973** (install via Android Studio SDK Manager)
  - CMake 3.22+ and Ninja (install via SDK Manager)

### Build

```bash
git clone https://github.com/Video-Codec-Acid-Test-VCAT/vcatd-vvdec-plugin.git
cd vcatd-vvdec-plugin
./gradlew dist
```

Output: `app/build/outputs/dist/vcatd-vvdec-plugin.aar`

> **Note:** The first build compiles vvdec from source for each ABI (~10–15 minutes). Subsequent builds are cached and fast.

One-off overrides: `-PvvdecRef=<tag/sha>`, `-PvvdecRemote=<url>`, `-PVVDEC_SRC=<path>` (or the
`VVDEC_SRC` environment variable).

### Using it with VCAT

Copy the AAR into VCAT's `decoder-plugins/` folder before building the app:

```bash
cp app/build/outputs/dist/vcatd-vvdec-plugin.aar ../vcat-d/decoder-plugins/
```

See the [VCAT build instructions](https://github.com/Video-Codec-Acid-Test-VCAT/vcat-d) for the full build workflow.

## iOS

The iOS build is a shell script. It doesn't use Gradle and needs no Android SDK or NDK, and
Gradle in turn ignores `ios/` and `native/`. The output is **one self-describing dynamic
library**, packaged as one `.xcframework`.

### Prerequisites

- **macOS with full Xcode**, including the iOS and iOS Simulator SDKs. The Command Line Tools
  alone are not enough. `xcode-select` must point at Xcode:
  ```bash
  xcode-select -p          # should print .../Xcode*.app/Contents/Developer
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer   # adjust to your Xcode's name
  ```
  Verified with Xcode 27.2.
- **CMake** (3.22 or newer) and **Ninja**:
  ```bash
  brew install cmake ninja
  ```
- **vcat-d-ios checked out next to this repo.** The build compiles against the plugin API header
  in vcat-d-ios's `plugin-api/vcat_decoder_plugin.h`, the one header shared by the app and all
  plugins:
  ```
  AndroidStudioProjects/
    vcatd-vvdec-plugin/    <- this repo
    vcat-d-ios/            <- provides plugin-api/vcat_decoder_plugin.h
  ```
  If it lives elsewhere, set `VCAT_PLUGIN_API_DIR=/path/to/vcat-d-ios/plugin-api`.
- **Network access** on the first build, to clone vvdec.

### Build

From the repo root:

```bash
ios/build_xcframework.sh
```

The first build compiles vvdec twice, once for the device and once for the simulator; it's a
large C++ codebase, so allow several minutes. Later runs reuse those builds unless the pinned
ref changes. A successful run ends with:

```
== vcat.vvdec  framework=vcatd_vvdec  vvdec=v3.2.0  api=v2
== iphoneos: vcatd_vvdec.framework exports _vcat_plugin_entry, manifest embedded
== iphonesimulator: vcatd_vvdec.framework exports _vcat_plugin_entry, manifest embedded
== built .../build/dist/vcatd-vvdec-plugin.xcframework
```

**Output:** `build/dist/vcatd-vvdec-plugin.xcframework`, a single drop-in:

```
vcatd-vvdec-plugin.xcframework/
  Info.plist
  ios-arm64/vcatd_vvdec.framework/             device
    vcatd_vvdec                                the dynamic library (vvdec + plugin glue)
    Info.plist                                 VCATDecoderPlugin = true
  ios-arm64-simulator/vcatd_vvdec.framework/   Apple Silicon simulator
    vcatd_vvdec
    Info.plist
```

There's no manifest file and no header. The plugin is **self-describing**: its manifest (id,
MIME type, API version, decoder source, license) is compiled into the library. The library
returns it at runtime via `manifest_json()`, and it's also stored in the library's
`__TEXT,__vcat_manifest` section, so the app's build can read it without running iOS code.

**For each slice, the script:**
1. Builds vvdec at the pin with CMake, as a static library, using the project's own minimal
   toolchain file `ios/cmake/ios.toolchain.cmake`.
2. Generates a header from `plugin.json` carrying the plugin identity and the manifest.
3. Compiles `native/vcat_plugin_vvdec.c`, the C ABI glue, and links it with vvdec into the
   framework's dynamic library using `clang++`. vvdec is C++, so the library carries its own
   libc++ dependency; the app needs no C++ link flags. The library **exports only
   `vcat_plugin_entry`**, the same entry name in every VCAT plugin.
4. Fails the build if anything else is exported, or if the embedded manifest doesn't read back.

Every plugin is its own dynamic library with its own symbol namespace, so vvdec's C++ internals
stay private, and plugins can never collide inside the app.

**Optional overrides,** as environment variables:

| Variable | Effect |
|---|---|
| `VVDEC_REF=<tag/sha>` | build a different vvdec than `plugin.json` pins |
| `VVDEC_REMOTE=<url>` | clone from a different vvdec repository |
| `VVDEC_SRC=<path>` | build from a local vvdec checkout |
| `VCAT_PLUGIN_API_DIR=<dir>` | location of `vcat_decoder_plugin.h` |
| `IPHONEOS_DEPLOYMENT_TARGET=<ver>` | minimum iOS version (default 17.0, matching vcat-d-ios) |

For a clean rebuild, remove the cached work: `rm -rf build/ios build/dist`.

### Verify (optional)

```bash
F=build/dist/vcatd-vvdec-plugin.xcframework/ios-arm64/vcatd_vvdec.framework/vcatd_vvdec
nm -gUj $F                                                    # exactly one: _vcat_plugin_entry
xcrun segedit $F -extract __TEXT __vcat_manifest /dev/stdout  # the embedded manifest
otool -L $F                                                   # libc++ and libSystem only
```

### Using it with vcat-d-ios

```bash
rm -rf ../vcat-d-ios/decoder-plugins/vcatd-vvdec-plugin.xcframework   # remove any older copy first
mkdir -p ../vcat-d-ios/decoder-plugins
cp -R build/dist/vcatd-vvdec-plugin.xcframework ../vcat-d-ios/decoder-plugins/
```

Then build vcat-d-ios; nothing else is needed (if the Xcode project was never generated, run
`xcodegen generate` once).
- **What the build does:** its "Embed decoder plugins" phase validates the plugin, copies it into
  the app and signs it. The app discovers it at launch.
- **What you'll see:** Conditions shows VVC as `vcat.vvdec`, and telemetry rows record
  `vcat-vvdec-3.2.0`, the same string as on Android.
- **Why remove the old copy first:** `cp -R` merges into an existing directory, which can leave
  stale files behind.

### Troubleshooting

| Symptom | Fix |
|---|---|
| `xcrun: error: SDK "iphoneos" cannot be located` | `xcode-select` points at the Command Line Tools. Select full Xcode (see Prerequisites) |
| `xcode-select: error: invalid developer directory` | The path doesn't match your Xcode's actual name, e.g. `/Applications/Xcode-27.2.0.app` |
| `cmake not found` / `ninja not found` | `brew install cmake ninja` |
| `.../vcat_decoder_plugin.h not found` | Check out vcat-d-ios next to this repo, or set `VCAT_PLUGIN_API_DIR` |
| `library must export only _vcat_plugin_entry` | A change exposed another symbol. Keep glue helpers `static` |
| vcat-d-ios: `built against plugin API vN, this app is vM` | The plugin API changed. Pull vcat-d-ios and rebuild the plugin |

## Dependencies

| Dependency | Version | License | Source |
|---|---|---|---|
| vvdec | 3.2.0 | Clear BSD | [fraunhoferhhi/vvdec](https://github.com/fraunhoferhhi/vvdec) |
| vcatd-decoder-plugin-api (Android) | 1.0.3 | GPL-3.0-or-later | Maven Central |
| vcat_decoder_plugin.h (iOS) | API v2 | GPL-3.0-or-later | vcat-d-ios `plugin-api/` |

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for full terms, third-party notices, and patent disclaimer.

For commercial licensing contact: legal@roncatech.com
