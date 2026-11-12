# Watch face availability research

## Hermès

Earlier investigation examined `-[CLKDevice _loadDeviceInfo]` and `MGCopyAnswer` in a watchOS simulator. Simulator experiments can help identify candidate paths, but their cache layout and behavior are not evidence for physical-device offsets. The physical OTA follow-up inspected MobileGestalt descriptors and callbacks. The implementation changes `DeviceBrand` in `CacheData` to the configured activation value `1`, removes its `CacheExtra` override, checks the result, and asks the user to restart Carousel.

The reverse-engineered `DeviceBrand` source is per-device `syscfg/MkBS` through `marketing-software-behavior`; an OTA for a product type does not by itself establish whether an individual device originally had an Hermès brand. The value `1` is an activation override, not a safe universal restore value. See [recovery](../Recovery/README.md).

A reported on-device result is not, by itself, proof that every consumer process reloaded the value or that all face styles will be supported. When testing, record the actual watch model, build, original cache, exact changes, restart performed, and where the face is visible. Do not share unredacted device-specific cache data.

## Ultra faces

The initial investigation considered `DeviceHousingColor` and an `isUltra` classification, but changing the observed color values did not establish a working or universal Ultra face path. Earlier attempts also considered whether a `ProductType` branch, additional MG keys, installed face bundles, and other NanoTimeKit availability checks were involved. Those are investigation leads; this record does not establish that any one of them is the complete condition.

The original Ultra Faces path writes `main-screen-class = 29` at the analyzed cache location and removes its corresponding `CacheExtra` override. The app now offers `29` and `38` for the six analyzed builds; neither is a universal original screen class. The alternative `38` requires a usable initial backup, a matching current and backup state, and no screen-class override. On `Watch7,18` / `24S5284h` the backup must contain `35`, matching the contributor’s reported experiment. On other models the backup is the reference; its correctness is not independently guaranteed. `24R359` retains only the existing `29` option. The project displays a warning that enabling Ultra Faces prevents use of the Hermès Faubourg Party face. A screenshot or another person's report of a particular face is evidence of that reported result only, not a substitute for a documented device/build test matrix.

In a watchOS 27.2.1 binary, static analysis found that the `main-screen-class` callback depends on `MainScreenStaticInfo`. This dependency matters when attempting to reconstruct a value using an isolated MG cache: the original callback can consult the global MG path. The implemented cross-check and its limits are documented in [recovery](../Recovery/README.md).

## ClockKit size classes and the alternative option

In the extracted physical OTA ClockKit binaries for `24R364`, `24R365`, `24S118`, `24S132`, `24S5112a`, and `24S5284h`, static analysis of `-[CLKDevice _loadDeviceInfo]` found `main-screen-class` 29 maps to size class 6 and 38 maps to size class 9. The category lookup maps those size classes to 4 and 6; the observed `isUltra` predicate `(category & ~2) == 4` accepts both. This is a classification observation, not a guarantee that any particular Ultra face, bundle, companion gallery preview, or layout works on every model. Other screen classes are not offered merely because they appear in the switch.

Extracted, slide-applied ClockKit SHA-256 values for the binaries inspected:

| Build | OTA model | SHA-256 |
| --- | --- | --- |
| `24R364` | `Watch7,11` | `8676743b6b1944399ec6416417f4c7777f7fbe5c1327d9b951d1491e055fad8c` |
| `24R365` | `Watch7,11` | `1d7b62f8063e980cdfcbdd9adeeeadd3d09889aeb59e79a9b3c35682eef417c7` |
| `24S118` | `Watch7,11` | `6acef83ea18f2a556dc9652284751d971d43b418bd862382532f8ff2d810fc0e` |
| `24S132` | `Watch7,11` | `908c3d1cf2c8f372af1cf8f2ff5c905be3b0c84b48b240bd5692cdcfa32ae465` |
| `24S5284h` | `Watch8,1` | `06d9fce636d972df52688c19912c1d3ff4590592293193c274f9a9cd5f85875f` |

For `24S5112a` / `Watch7,9`, `_loadDeviceInfo` at `0x1b7ce6d00` maps 29 to size class 6 and 38 to size class 9; the table at `0x1b7d20128` maps these to categories 4 and 6, and the predicate at `0x1b7ce7e38` accepts both. This is static evidence; the presence offset and on-device behavior remain unverified.

The model names identify OTA inputs, not successful runtime tests on those watches. Inspect the switch, category lookup table, and `isUltra` predicate again when adding a build. These hashes are for extracted outputs and may depend on extraction or slide-processing tooling.

The `38` path is based on [PR #48](https://github.com/pookjw/HermesEnabler/pull/48), whose author reported Modular Ultra and red night mode on `Watch7,18` / `24S5284h` with `35 → 38`. The PR's example was not compiled into that PR; this implementation adapts its checks and the existing automatic backup mechanism. We have not independently repeated its device test. Changing screen classification affects more than the Ultra gallery: faces and complications can clip or render incorrectly, especially on a smaller physical display. Selecting an available class writes it to MG immediately, including when Ultra Faces is already enabled; the picker reads its state from the cache. Restart the watch to reload consumers. Disabling Ultra Faces restores the backup value. Gallery preview failures remain unresolved.

## Open questions

- Which specific face bundles and NanoTimeKit checks are necessary on each physical model and build?
- Does the iPhone Watch app's face gallery use the same device properties and refresh at the same time as watch-side processes?
- What other interactions are caused by changing screen class, beyond the Faubourg Party incompatibility noted in the UI?
- Can the original `main-screen-class` be independently verified on physical devices across screen sizes and runtime display variants?

Do not treat an unverified model mapping, a simulator result, or an unchanged cache UUID as proof of a specific physical watch's original state.

For `24R5315i` / `Watch7,9`, physical OTA ClockKit static analysis likewise maps 29 to size 6 and 38 to size 9; the category table maps them to 4 and 6, and `(category & ~2) == 4` accepts both. This does not establish face availability or working layouts on a watch. See [OTA research](../OTA/README.md).
