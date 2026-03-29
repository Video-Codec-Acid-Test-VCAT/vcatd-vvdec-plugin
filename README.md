# vcatd-vvdec-plugin

VVC/H.266 software decoder plugin for [VCAT (Video Codec Acid Test)](https://github.com/Video-Codec-Acid-Test-VCAT/vcat-d).

Wraps [vvdec](https://github.com/fraunhoferhhi/vvdec) (Fraunhofer H.266 decoder) as a VCAT decoder plugin, loaded dynamically by the VCAT app at runtime.

## Prerequisites

- JDK 17+
- Android SDK with:
  - NDK **27.0.12077973** (install via Android Studio SDK Manager)
  - CMake 3.22+ and Ninja (install via SDK Manager)

vvdec is fetched and built from source automatically on first build.

## Build

```bash
git clone https://github.com/Video-Codec-Acid-Test-VCAT/vcatd-vvdec-plugin.git
cd vcatd-vvdec-plugin
./gradlew :app:dist
```

Output: `app/build/outputs/dist/vcatd-vvdec-plugin.aar`

> **Note:** The first build compiles vvdec from source for each ABI (~10–15 minutes). Subsequent builds are cached and fast.

## Using the Plugin with VCAT

Copy the AAR into VCAT's `decoder-plugins/` folder before building the app:

```bash
cp app/build/outputs/dist/vcatd-vvdec-plugin.aar ../vcat-d/decoder-plugins/
```

See the [VCAT build instructions](https://github.com/Video-Codec-Acid-Test-VCAT/vcat-d) for the full build workflow.

## Dependencies

| Dependency | Version | License | Source |
|---|---|---|---|
| vvdec | 3.0.0 | Clear BSD | [fraunhoferhhi/vvdec](https://github.com/fraunhoferhhi/vvdec) |
| vcatd-decoder-plugin-api | 1.0.1 | GPL-3.0-or-later | Maven Central |

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for full terms, third-party notices, and patent disclaimer.

For commercial licensing contact: legal@roncatech.com
