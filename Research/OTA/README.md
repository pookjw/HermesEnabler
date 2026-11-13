# Physical OTA research and reproduction

## Dataset and scope

The research used physical-device full OTA assets obtained from Apple's update service, rather than simulator runtime binaries, to derive the shipped cache layouts. On the research machine the original files and generated reports are under `~/Desktop/watchOS OTA/`; that location is not part of the repository and may not exist on other machines.

| watchOS label | Build | Model-specific OTA assets in the catalog used here |
| --- | --- | ---: |
| 27.0 | `24R364` | 23 |
| 27.0.1 | `24R365` | 23 |
| 27.2 | `24S118` | 23 |
| 27.2.1 | `24S132` | 23 |
| 27.3 beta 1 | `24S5284h` | 23 |

The recorded set contains **115 assets and 115 parsed device-tree results**. Downloads were compared with the SHA-256 values available in the collected update metadata. This establishes that those files match the expected hashes in that research catalog; it is not an independent proof of every binary interpretation. Queries performed during this investigation did not return a physical full OTA for `24R359`; do not infer that it cannot exist elsewhere.

Two further single-model physical OTAs were analyzed later, outside that 115-asset catalog: `24R363` (`Watch8,2`) and `24S5086l` (`Watch7,9`). They are described in their own sections below. They are not counted in the 115-asset totals, and their library hashes are fingerprints rather than comparisons against an independent expected digest.

On 2026-11-12, a subsequent search for `24S5112a` returned no matching Full OTA from the Pallas query. A 461,373,440-byte [Apple CDN update asset](https://updates.cdn-apple.com/2026FallFCS/6c21cab1-6e9d-4b61-904c-7bdd1ab87cee/com_apple_MobileAsset_SoftwareUpdate/ee8eea2b07aae7230ef445bc716d8bbd381487157bb80ec718f06511b5533923.aea), listed for a `24S5112a` prerequisite, was downloaded for `Watch7,9`. Its local SHA-256 was `5d76ca7f3ad060194f97ce3ea20d924b5233efdcee8e148cd545a0852ec157b7`; no independent expected SHA-256 was available for comparison. `ipsw ota info` reported target build `24S118`, and dyld extraction found sidecars without a primary cache. It therefore cannot establish the `24S5112a` MobileGestalt offsets or callbacks; `RecoveryVerified` remains false. The update's prerequisite relationship comes from the [OTA catalog listing](https://theapplewiki.com/wiki/OTA_Updates/Apple_Watch/27.2), while its target build was checked in the downloaded asset's metadata.

The device-tree templates were parsed for every asset. The MobileGestalt descriptor study covered each of the five listed builds and selected device/architecture comparisons; it did **not** extract and compare `libMobileGestalt` from all 115 assets. A table entry derived from one architecture must not be presented as verified for every model without the appropriate comparison.

## Preserved local artifacts

| Artifact | Contents and limitation |
| --- | --- |
| `OTA-manifest.json` | File name, model, build, URL, size and expected SHA-256 for the collected assets. |
| `ota_fcs_keys.json` | AEA keys associated with the update URLs, as collected for extraction; this is not an individual device backup. |
| `OTA-download.log`, `OTA-resume.log` | Download and checksum verification records. |
| `OTA-device-tree-analysis.json` | The 115 extracted template observations; properties may be filled or overridden at boot. |
| `OTA-mobilegestalt-descriptors.json` | Selected opaque key identifiers, indices, value offsets, types and flags for each analyzed build. |
| `Recovery-analysis-notes.md` | Earlier local notes; prefer this repository's documents when describing the current implementation. |

These reports are local research artifacts, not checked-in fixtures. Save the relevant sources, SHA-256s, tool version, exact commands, and sanitized observations when repeating the study. Do not upload a user's MG cache or private device data to make an example reproducible.

## Reference assets

The expected hashes below identify the physical OTA input, not a simulator. URLs are Apple CDN URLs recorded in the collected catalog; their continued availability is not guaranteed.

| Build | Model | Bytes | Expected SHA-256 | Recorded source |
| --- | --- | ---: | --- | --- |
| `24R364` | `Watch7,20` | 3,959,422,976 | `cfc7dfe2e9e5a1f94a1b2aef817be8b719ead41af03ce0b85752cb9cca423eb2` | [Apple OTA asset](https://updates.cdn-apple.com/2026SFallCS/06a36bd1-1f3d-4638-99ff-ee7751c2f222/com_apple_MobileAsset_SoftwareUpdate/291220ee675e188f64b5e1655394e47f01b206916bd4b6a940c929a293d4595e.aea) |
| `24S132` | `Watch7,11` | 3,959,422,976 | `58756349b706f4f697b07fd1b35186d6b494eb51896ca03f8e1c0040dbe58dcb` | [Apple OTA asset](https://updates.cdn-apple.com/2026FallFCS/23babb1c-b397-4286-90d8-8d1ff5c24b6b/com_apple_MobileAsset_SoftwareUpdate/427ae1a0dc64db42662fce0a5bab94fb48f54d2e755663a9fdb1915eb156ef0a.aea) |
| `24S5284h` | `Watch8,1` | 4,294,967,296 | `0b6c0c356f67a7ae35a17fb4f87086633d975d95ad5dfb3f8f148b4a0046c880` | [Apple OTA asset](https://updates.cdn-apple.com/2026FallSeed/ecf524cb-5315-408d-8e3f-9fb9d80be10c/com_apple_MobileAsset_SoftwareUpdate/e20d2647e8059b7ed15aa1259459402a1382c076e4eb476fa51f6448734d479f.aea) |
| `24R363` | `Watch8,2` | 3,959,422,976 | `3c5b3d31857fdf6f432120973e8a6c5011d3975354cc750593510d3f5046748c` | [Apple OTA asset](https://updates.cdn-apple.com/2026SFallCS/b5876040-2394-4edb-9608-b039f53d9d7c/com_apple_MobileAsset_SoftwareUpdate/2fb17b4410713512c9e56fbd6ec903dee77e4d9ef1a1164e028a7c633be0b7cb.aea) |
| `24S5086l` | `Watch7,9` | 3,892,314,112 | `6bd7ee13ff65f3036f64ebde071785c28134ddebcfcebe05fedf26aeb5acd192` | Local physical full OTA; source URL not preserved |

As one cross-model check, the extracted `libMobileGestalt.dylib` from `Watch7,20` `24R364` had SHA-256 `f5919ff54a806a7b0dc11eed47049237c3f5dc1bdae0be4d32d38a633ea0c6cc`, matching the `Watch7,11` `24R364` extracted library used in that comparison. For `24S132`, `Watch7,11` and `Watch8,1` extracted libraries had different hashes; 25 selected stored descriptor indices and kinds matched between the two. Four additional compared descriptors used the unstored `0xffff` index on both; that is not evidence that all code or all descriptors match across architectures.

The analysis used [blacktop/ipsw](https://github.com/blacktop/ipsw), version `3.1.739` (Homebrew build), plus local scripts and disassembly. Tool behavior and OTA formats can change; record the actual version used in a new investigation.

## Repeatable workflow

1. Obtain a physical-device **full OTA** for the exact model and build. Preserve the update metadata source and expected SHA-256 separately. Confirm file size and compare the downloaded file's SHA-256 with that source:

   ```sh
   shasum -a 256 "$OTA_PATH"
   ```

   `$OTA_PATH` is a researcher-supplied path. Compare the result explicitly; a successful `shasum` command only means the hash was calculated.

2. Obtain the corresponding AEA decryption key from the authorized OTA metadata/key source. With a compatible local key database, inspect the device-tree template and extract the dyld cache:

   ```sh
   ipsw dtree "$OTA_PATH" --key-db "$KEY_DB_PATH" --json > device-tree.json
   ipsw ota extract "$OTA_PATH" --key-db "$KEY_DB_PATH" --dyld --confirm --output "$OUTPUT_DIR"
   ipsw dyld extract "$DYLD_CACHE_PATH" libMobileGestalt.dylib --slide --output "$OUTPUT_DIR/mg"
   ```

   Set the paths for the actual asset, matching key database, output directory, and architecture-specific dyld cache. `--key-val` can be used when a matching key database is unavailable, but avoid putting keys into shared logs or committed shell history. The first two commands do not modify a watch; they process the OTA input.

3. Inspect `libMobileGestalt.dylib` for the relevant opaque key identifier and its descriptor. Record the selected architecture, descriptor index and type, callback address, and how the address maps into the extracted Mach-O. For the layouts studied here, compare the descriptor index to `CacheData`'s eight-byte value slots and its presence region, then independently check the resulting byte positions and UUID against a suitable cache of the **same** build. Hash the extracted library and preserve the disassembly needed to explain each conclusion.
4. Trace the callback and its dependencies. Determine whether it reads a device-tree property, another global MG answer, a model check, or per-device `syscfg`. Compare the template with a runtime property only on a device you are authorized to inspect. Record absent properties and access failures separately.
5. Check [`MGOffsets.plist`](../../HermesEnabler2/MGOffsets.plist) and [`MGDefaults.plist`](../../HermesEnabler2/MGDefaults.plist) for the exact build. Validate UUID, length, bounds, presence offsets, value types and callback semantics. A copied adjacent-build layout is a hypothesis, not an independently verified offset.
6. Re-run the existing parser tests and watchOS build after changes:

   ```sh
   clang -std=c11 -Wall -Wextra -Werror tests/BQRecoveryValidationTests.c -o /tmp/hermes-recovery-tests
   /tmp/hermes-recovery-tests
   xcodebuild -project HermesEnabler2.xcodeproj -scheme HermesEnabler2 -configuration Debug -sdk watchos -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
   ```

   These checks do not validate private API access, cache writes, face availability, or recovery on real hardware. Record those tests separately if they are performed.

## Interpreting templates

All 115 templates in this dataset recorded `marketing-software-behavior` as `syscfg/MkBS` and `region-info` as `syscfg/Regn/0x20,zeroes/0x20`. Across the collected build/model set, 15 entries had an `app` button in addition to `help` and `menu`; keyboard and AOD Vibrancy property presence varied by model. The analysis script observed `watch-gestures`, `env-audio-exp-capable`, and `always-on-time` property names in all 115 templates. These are observations about template structure, **not** proof that all watches support each user-facing feature or that a property remains unchanged at runtime. A data property with an empty/null decoded value can still be present; absence and the value of a present property must not be conflated.

A separate [Apple CDN Full OTA](https://updates.cdn-apple.com/2026FallSeed/757182ff-8a24-4062-a898-a2cf76d9d831/com_apple_MobileAsset_SoftwareUpdate/231a8f08bf381e535c7c6a56491549c84df8e68ef5a6e2f8a810f74d3529b552.aea) was subsequently found via a third-party catalog and downloaded. The `ipsw ota info` build manifest identifies `Watch7,9` and build `24S5112a`; the catalog listed no prerequisite. Its 3,892,314,112 bytes match the catalog size. The locally calculated SHA-256 is `acc81a9812bd61b2b494553f079aaabb2bbe4167af8c2f599d3e56bcfbbe7710`; an independent expected digest was not available, so this is an identifier rather than a checksum comparison.

The OTA yielded the physical arm64e dyld shared cache and `libMobileGestalt.dylib`. Its descriptors identify `DeviceBrand` as index `0x69` (value offset `0x348`) and `main-screen-class` as index `0x1d6` (value offset `0xeb0`). The eight Boolean indices are `0xae`, `0xb0`, `0xaf`, `0x2b9`, `0xda`, `0x2bb`, `0x9d`, and `0xdd`, respectively, in the order in the MobileGestalt research table. They match the current plist. The descriptor comparison does not independently verify the cache UUID, presence offsets, callback semantics or on-device recovery; `RecoveryVerified` remains false.

## watchOS 27.0 beta 3 (`24R5315i`)

A [physical-device Full OTA for `Watch7,9`](https://updates.cdn-apple.com/2026SummerSeed/mobileassets/140-34573/68D2F28A-0027-43D3-B653-1271C91C63B3/com_apple_MobileAsset_SoftwareUpdate/5f2d0f06115b125656da9e08660a8f4428bd5dd8b32bf2c92bc0c57c23854d5e.aea) was downloaded and inspected with `ipsw`. Its build manifest identifies `Watch7,9` and `24R5315i`. Its 3,892,314,112-byte size matches the [catalog listing](https://theapplewiki.com/wiki/Beta_OTA_Updates/Apple_Watch/27.0). Its computed SHA-256 is `ebbdcf8bb077e3f4852bed3ccd58f32f600baf47b5586caeab775f908879b71e`; no independent expected SHA-256 was available, so this is a fingerprint, not a comparison.

The extracted arm64e `libMobileGestalt.dylib` SHA-256 is `3fd6bdc27e698077abc584d78918a7eede98e39cacfbfaf5348bc69110e63299`. Its embedded cache UUID is `A4A7B9EC-7C2A-4E22-B1D2-179C9F27F6F1`. `_MGCreateInMemoryCache` allocates `0x1947` bytes, and its setter accesses eight-byte slots with presence bytes at `0x1678 + index`. The observed `DeviceBrand` and `main-screen-class` descriptor indices are `0x69` and `0x1d5`, yielding value/presence offsets `0x348`/`0x16e1` and `0xea8`/`0x184d`. The eight primary Boolean indices match `24R364`. Eleven additional stored descriptor indices also match `24R364`; `W2RPjaqovtsgiRB6ScePGA` and `rb2tKZxlj0Gm2tBmUQSLqQ` were not found in this binary, and the swimming-workout descriptor has the unstored index `0xffff`. They are omitted from `AdditionalIndexes`.

The extracted ClockKit SHA-256 is `2322ef9b1e6a560c6e0c77a5050443ee5ad85bc8d6c832f93819e58add9d7774`. In `-[CLKDevice _loadDeviceInfo]`, screen classes 29 and 38 select sizes 6 and 9, whose table entries are categories 4 and 6. The `isUltra` predicate accepts both. These are static observations; neither feature behavior nor the cache layout has been tested on a physical watch running this build. The system-derived recovery callbacks have not been verified, so `RecoveryVerified` remains false. The observations do not establish support for every feature on every model.

## watchOS 27.0 RC (`24R363`)

A physical `Watch8,2` Full OTA was downloaded from the Apple CDN asset listed in the reference table above. Its 3,959,422,976-byte size matches the catalog size. The locally computed SHA-256 is `3c5b3d31857fdf6f432120973e8a6c5011d3975354cc750593510d3f5046748c`; no independent expected digest was available, so this is a fingerprint rather than a checksum comparison. The AEA key was taken from the Apple Wiki OTA catalog. `ipsw ota extract --dyld` produced the arm64e dyld shared cache and `libMobileGestalt.dylib`.

The extracted `libMobileGestalt.dylib` SHA-256 is `a2e9c6ccc52e7146bddcb101d2475e32e869b77341a3cce9f0df91fa5067816f`. Its embedded cache UUID is `6F8372B0-1583-4031-A4BC-A54A18B0DD5A`, the same UUID as `24R364` / `24R365` / `24R359`. `_MGCreateInMemoryCache` allocates `0x1947` bytes, and its setter reads the 16-bit descriptor index at `+0x3a` and uses presence bytes at `0x1678 + index`. The observed `DeviceBrand` and `main-screen-class` descriptor indices are `0x69` and `0x1d5`, yielding value/presence offsets `0x348`/`0x16e1` and `0xea8`/`0x184d`. The eight primary Boolean indices and all 13 additional stored descriptor indices match `24R364`; the swimming-workout descriptor has the unstored index `0xffff`.

The extracted ClockKit SHA-256 is `c3958fe5863ce4a535596d44ff6e5b750471501d2f2ab7474a3fc6e0ee825cab`. In `-[CLKDevice _loadDeviceInfo]`, screen classes 29 and 38 select sizes 6 and 9, whose table entries are categories 4 and 6; the `_isUltra` assignment accepts those categories. The DeviceBrand handler reads byte 2 of `marketing-software-behavior` from `IODeviceTree:/chosen`, requires at least four bytes, and maps values 1–2 to themselves and everything else to 0, which is why `MaxDeviceBrand` is 2. These are static observations. Neither feature behavior nor the cache layout was tested on a physical watch running this build, and the system-derived recovery callbacks were not verified, so `RecoveryVerified` is false.

## watchOS 27.2 beta 1 (`24S5086l`)

A physical `Watch7,9` Full OTA was analyzed. The local asset is 3,892,314,112 bytes with SHA-256 `6bd7ee13ff65f3036f64ebde071785c28134ddebcfcebe05fedf26aeb5acd192`; the source URL was not preserved, so no independent expected digest is available. `ipsw ota extract --dyld` produced the arm64e dyld shared cache and `libMobileGestalt.dylib`.

The extracted `libMobileGestalt.dylib` SHA-256 is `78851158f1e0aef22d469c4da0d37ce0b2f30d46af6596a4c935ccfa0b93eebe`. Its embedded cache UUID is `E7D9878A-EC20-4CED-AFA4-5AA134AC5F20`, distinct from the `24S118` / `24S132` / `24S5284h` UUID despite sharing the `0x1950` layout. `_MGCreateInMemoryCache` allocates `0x1950` bytes and uses presence bytes at `0x1680 + index`. The `DeviceBrand` and `main-screen-class` indices are `0x69` and `0x1d6`, yielding `0x348`/`0x16e9` and `0xeb0`/`0x1856`. The eight primary Boolean indices (`0xae`, `0xb0`, `0xaf`, `0x2b9`, `0xda`, `0x2bb`, `0x9d`, `0xdd`) and all 13 additional stored descriptor indices match the `24S118` family. The extracted ClockKit SHA-256 is `9621f8852f08c12b3386f35b373c2b88cc0a03659366307dd6906aa2752a839b`; it maps screen class 29 to size 6 and 38 to size 9, with `_isUltra` accepting the corresponding categories. The DeviceBrand handler matches `24R363`: it reads byte 2 of `marketing-software-behavior`, requires at least four bytes, and accepts only 1–2, so `MaxDeviceBrand` is 2.

These are static observations from the OTA. The cache UUID, length and descriptor offsets are independently derived for this build, but no runtime answer, cache write or recovery callback was exercised on a watch running it. `RecoveryVerified` remains false.
