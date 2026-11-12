# MobileGestalt cache layout and write paths

## Scope and terminology

HermesEnabler2 modifies the on-device MobileGestalt cache plist using the file access mechanism in [`BQCore.m`](../../HermesEnabler2/BQCore.m). The cache has at least three fields relevant to this investigation:

- `CacheData`: a binary data blob with build-dependent positions for cached values and presence markers.
- `CacheExtra`: a dictionary whose entries use opaque identifiers associated with MG keys.
- `CacheUUID`: a layout identifier used, together with build and data length, to reject an unexpected cache.

The opaque names are sometimes called “encrypted keys” in discussion. These notes call them *opaque identifiers*: the observations here do not establish the encoding algorithm. A value's **logical MG key**, its `CacheExtra` identifier, and the offset of its entry in `CacheData` are different things.

## Why not use only a dictionary key?

For the face-related values studied here, adding or changing an entry in `CacheExtra` was not sufficient to reliably control the corresponding numeric answer in the investigated setup. A value was observed through `MGCopyAnswer` that did not equal the requested numeric value. That observation alone does not establish the returned value's internal representation or a universal precedence rule for every MG key and OS build.

Static analysis found numeric cache slots for `DeviceBrand` and `main-screen-class`; the current app writes the corresponding four-byte little-endian value in `CacheData`, checks the presence marker, and removes the related `CacheExtra` override when enabling. For these keys, the byte positions come from the descriptor tables in physical OTA `libMobileGestalt.dylib`, not from a simulator cache. The app also checks the build, UUID, data length, and bounds before writing, then reads the cache back.

This is **not** a claim that every MG key requires an offset. Most Boolean feature toggles currently write their opaque key in `CacheExtra` through `bq_setMGCacheExtraKeys`. The backup-based recovery path for a subset of those features can additionally restore their indexed `CacheData` slot and presence marker. See [recovery](../Recovery/README.md) for the exact scope.

## Numeric values used for face activation

| Logical key | Opaque `CacheExtra` identifier | Activation value | Current treatment |
| --- | --- | ---: | --- |
| `DeviceBrand` | `fuKL2rMywRgQF1wowOA/cg` | `1` | Write the four-byte value at `DeviceBrandOffset`; remove this override when enabling. |
| `main-screen-class` | `fdh+s6j3VijuyrK7xLjd7g` | `29` (existing) or `38` (alternative) | Write the selected four-byte value at `ScreenClassOffset`; remove this override when enabling. |

These values are **activation overrides**, not factory defaults. The `38` alternative is offered only on the five analyzed builds; `24R359` remains limited to the existing `29` because its physical OTA was not verified. See [`MGDefaults.plist`](../../HermesEnabler2/MGDefaults.plist). Neither a value of `29` nor a visible switch proves that all face bundles, layouts, or compatibility checks are satisfied.

## Layouts recorded in the app

The canonical machine-readable table is [`MGOffsets.plist`](../../HermesEnabler2/MGOffsets.plist). Values below are byte offsets in `CacheData`, shown in hexadecimal. The selected Boolean descriptors use an eight-byte slot at `8 * index`, with a presence byte at `PresenceBase + index` in these analyzed layouts; this must be revalidated on another build.

| Builds | UUID | Length | Brand value / presence | Screen value / presence | Presence base |
| --- | --- | ---: | --- | --- | ---: |
| `24R364`, `24R365` | `6F8372B0-1583-4031-A4BC-A54A18B0DD5A` | `0x1947` | `0x348` / `0x16e1` | `0xea8` / `0x184d` | `0x1678` |
| `24S118`, `24S132` | `32B4CA84-FBDA-496C-9B79-2101D597158B` | `0x1950` | `0x348` / `0x16e9` | `0xeb0` / `0x1856` | `0x1680` |
| `24S5284h` | `DB380F61-0014-418D-9799-876666B459E3` | `0x1950` | `0x348` / `0x16e9` | `0xeb0` / `0x1856` | `0x1680` |
| `24R359` | `6F8372B0-1583-4031-A4BC-A54A18B0DD5A` | `0x1947` | `0x348` / `0x16e1` | `0xea8` / `0x184d` | `0x1678` |
| `24S5112a` | `830A9A56-15CC-4BB4-A1C3-F5F6FDB79819` | `0x1950` | `0x348` / `0x16e9` | `0xeb0` / `0x1856` | `0x1680` |

`24R359` is an **assumption** copied from `24R364`, not an independently verified physical full OTA. Its plist entry has `RecoveryVerified = false`: the ordinary face write path accepts its configured layout, but the experimental system-derived recovery paths reject it. A matching UUID is useful evidence, not proof that all field semantics are identical.

For `24S5112a`, the contributor of [PR #52](https://github.com/pookjw/HermesEnabler/pull/52) reported successful Hermès activation on `Watch7,9` and supplied its cache UUID and face offsets. The descriptor records in the physical `Watch7,9` Full OTA match the configured DeviceBrand, screen-class and all eight Boolean indices. The cache UUID, length and presence-byte layout remain reported values rather than independently verified runtime observations. Its entry has `RecoveryVerified = false` because the recovery callback semantics and runtime behavior have not been fully validated; Ultra screen-class choices 29 and 38 are configured based on ClockKit analysis. See [OTA research](../OTA/README.md).

Selected Boolean descriptor indices:

| Feature | MG key | Opaque identifier | `24R364` / `24R365` | `24S118` / `24S132` / `24S5284h` |
| --- | --- | --- | ---: | ---: |
| AOD | `DeviceSupportsAlwaysOnDisplay` | `2OOJf1VhaM7NxfRok3HbWQ` | 173 | 174 |
| AOD time | `DeviceSupportsAlwaysOnTime` | `j8/Omm6s1lsmTDFsXjsBfA` | 175 | 176 |
| AOD 1 Hz | `DeviceSupportsAlwaysOnDisplayFlipbook` | `aoJSd/MXk7M40NgXTM6x+g` | 174 | 175 |
| Action Button | `WatchAppButtonCapability` | `FBw/2WrPE2supEKosxxoTw` | 696 | 697 |
| Double Tap | `DeviceSupportsElton` | `l1CWke97nbaAcWDqA6T5LA` | 217 | 218 |
| Keyboard | `WatchKeyboardCapability` | `MQJ1mlVrhOwaUUVJehJSVA` | 698 | 699 |
| AOD Vibrancy | `DeviceSupportsAODVibrancy` | `ykpu7qyhqFweVMKtxNylWA` | 156 | 157 |
| Noise Exposure | `DeviceSupportsEnvironmentalDosimetry` | `SaW+DA+cbiqDHrex8MTABA` | 220 | 221 |

These index values document the descriptor analysis and the app's assumptions. They do not imply that enabling a capability supplies missing physical hardware or that every consumer uses that one key.

The `24S5112a` OTA descriptor indices match the `24S118` / `24S132` / `24S5284h` column for all eight Boolean keys. The broader recovery semantics have not been verified.

## Adding a build

Follow the [physical OTA workflow](../OTA/README.md). Do not copy offsets just because the marketing version looks similar or the cache length matches. Identify the physical build, extract its own library and descriptor records, compare all relevant indices and callback semantics, and verify the actual cache's UUID and length. Set `RecoveryVerified` to true only when the evidence supports the recovery paths as well as the offsets. Record which architecture and models were actually examined; device-tree coverage is not the same as extracting a library for every model.
