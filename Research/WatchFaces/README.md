# Watch face availability research

## Hermès

Earlier investigation examined `-[CLKDevice _loadDeviceInfo]` and `MGCopyAnswer` in a watchOS simulator. Simulator experiments can help identify candidate paths, but their cache layout and behavior are not evidence for physical-device offsets. The physical OTA follow-up inspected MobileGestalt descriptors and callbacks. The implementation changes `DeviceBrand` in `CacheData` to the configured activation value `1`, removes its `CacheExtra` override, checks the result, and asks the user to restart Carousel.

The reverse-engineered `DeviceBrand` source is per-device `syscfg/MkBS` through `marketing-software-behavior`; an OTA for a product type does not by itself establish whether an individual device originally had an Hermès brand. The value `1` is an activation override, not a safe universal restore value. See [recovery](../Recovery/README.md).

A reported on-device result is not, by itself, proof that every consumer process reloaded the value or that all face styles will be supported. When testing, record the actual watch model, build, original cache, exact changes, restart performed, and where the face is visible. Do not share unredacted device-specific cache data.

## Ultra faces

The initial investigation considered `DeviceHousingColor` and an `isUltra` classification, but changing the observed color values did not establish a working or universal Ultra face path. Earlier attempts also considered whether a `ProductType` branch, additional MG keys, installed face bundles, and other NanoTimeKit availability checks were involved. Those are investigation leads; this record does not establish that any one of them is the complete condition.

The implemented Ultra Faces path instead writes `main-screen-class = 29` at the analyzed cache location and removes its corresponding `CacheExtra` override. This was adopted as an activation strategy after further investigation; `29` is **not** the original screen class for every watch. The project displays a warning that enabling Ultra Faces prevents use of the Hermès Faubourg Party face. A screenshot or another person's report of a particular face is evidence of that reported result only, not a substitute for a documented device/build test matrix.

In a watchOS 27.2.1 binary, static analysis found that the `main-screen-class` callback depends on `MainScreenStaticInfo`. This dependency matters when attempting to reconstruct a value using an isolated MG cache: the original callback can consult the global MG path. The implemented cross-check and its limits are documented in [recovery](../Recovery/README.md).

## Open questions

- Which specific face bundles and NanoTimeKit checks are necessary on each physical model and build?
- Does the iPhone Watch app's face gallery use the same device properties and refresh at the same time as watch-side processes?
- What other interactions are caused by changing screen class, beyond the Faubourg Party incompatibility noted in the UI?
- Can the original `main-screen-class` be independently verified on physical devices across screen sizes and runtime display variants?

Do not treat an unverified model mapping, a simulator result, or an unchanged cache UUID as proof of a specific physical watch's original state.
