# Original-value recovery and backup research

## Backup lifecycle

The UI requires the user to explicitly create the initial backup before reaching the main settings screen. [`BQCore.m`](../../HermesEnabler2/BQCore.m) writes it as `OriginalGestalt.plist` in the app's Documents directory and will not overwrite an existing file at that path. It validates the presence of `CacheData` and `CacheExtra`, not whether the contents are truly factory-original.

Before `BQSaveGestalt` writes a changed cache, it creates a separate `auto-<UUID>.plist` backup under `MGBackups`. Manual backups also use that directory. A full backup restore creates an automatic backup first and checks cache UUID and data length; it then compares the restored file with the selected backup. Automatic backups capture the *current state before a write*. They do not automatically replace or become the initial backup, and a previously modified current cache produces a modified backup.

An initial backup created after an earlier modification can look structurally valid. The app cannot generally detect that it was already changed. If that backup contains a usable value, the restore path may treat it as original. An update-related report of missing data did not establish the cause; do not claim that updating always preserves data or that reinstalling or an identifier change is the only explanation. Bundle identifier, signing/container identity, reinstall, and backup timing are relevant facts to collect.

## What happens when a supported toggle is disabled

1. For Hermès and Ultra Faces, the app first attempts to use the corresponding initial-backup cache slot and original `CacheExtra` override. For the explicitly recoverable Boolean keys, it checks the initial backup's relevant override and/or valid indexed slot.
2. If a relevant backup value is unavailable or incompatible, the applicable native recovery function attempts to compute and cross-check that key's value. Only the selected setting is changed; AOD and AOD 1 Hz have separate paths.
3. If a multi-key Boolean setting has only a *partially* usable backup, the current code stops with an error rather than mixing that partial backup with a native fallback.
4. If recovery succeeds, `BQSaveGestalt` first saves an automatic backup of the current cache, writes the selected change, and performs a read-back check. If a source or validation step fails, the operation reports an error instead of intentionally guessing a value.

This is not a universal factory-reset mechanism. Boolean keys outside the explicitly recoverable set still use the ordinary `CacheExtra` setter when an initial backup exists. The UI's initial-backup gate prevents navigation to toggles when no valid initial backup is present; consequently, a no-backup fallback is not normally reachable from the initial screen. More importantly, making a new initial backup after data loss can preserve already-modified values, preventing the fallback from being selected.

## Why a separate MG cache helps — and why it is not enough

On the analyzed physical OTA libraries, the app dynamically resolves `MGCreateInMemoryCache`, `MGCopyAnswerWithCache`, and `MGCacheDestroy`, and asks for selected answers using a new empty in-memory cache. This attempts to force the selected handlers to compute answers rather than returning that cache's injected value.

A cache miss is **not** a guarantee of independence: a handler can call another MG API backed by the process/global cache. In particular, the analyzed `main-screen-class` handler obtains `MainScreenStaticInfo` through the global path. The app also asks the isolated cache for `MainScreenStaticInfo`, expects 24 bytes, extracts the class at byte offset 20, and requires agreement with the class answer. This is a cross-check, not a proof that every dependency is independent. Empty-cache isolation was exercised on the Mac host; that is not a watchOS device verification.

## DeviceBrand

Static analysis of the physical OTA handler tied `DeviceBrand` to the `marketing-software-behavior` property under `IODeviceTree:/chosen`. The app reads byte 2 from a data property of at least four bytes. For the studied release builds, values 1–2 are accepted; for `24S5284h`, 1–3 are accepted; other raw values map to 0. The upper limit is `MaxDeviceBrand` in [`MGDefaults.plist`](../../HermesEnabler2/MGDefaults.plist): it is a validation bound, **not** a value written as the device's default. The app requires the calculated value to match the isolated `DeviceBrand` answer and validates the expected cache slot before restoring it.

The OTA device-tree template records the source as `syscfg/MkBS`, so the OTA alone does not identify a particular watch's original brand. A model identifier cannot safely stand in for whether an individual unit was originally Hermès. `HermesEnabledDeviceBrand = 1` is the activation override, not a universally correct value to restore.

## Other investigated inputs

These are static-analysis conclusions for the five analyzed physical builds. Runtime API access and actual writes remain unverified on a physical watch.

| Setting | Runtime input / check | Conservative fallback |
| --- | --- | --- |
| Ultra Faces | Isolated `main-screen-class` compared with separately computed `MainScreenStaticInfo` | Restore only when the checks and slot validation pass. |
| Action Button | `IODeviceTree:/buttons` → NUL-terminated `button-names`; require both `help` and `menu`, and compare `app` presence with `WatchAppButtonCapability` | Can restore true or false when the complete readable list and MG agree. |
| Double Tap | `IODeviceTree:/product` → `watch-gestures`; compare with `DeviceSupportsElton` | Restore true only when property presence and MG true are confirmed. |
| Keyboard | `IODeviceTree:/product` → `watch-keyboard`; compare with `WatchKeyboardCapability` | Restore true only when both checks pass. |
| AOD / 1 Hz | `IODeviceTree:/arm-io/disp0` → `always-on-time`; compare with isolated `DeviceSupportsAlwaysOnTime` | For studied handlers, a confirmed true time capability supports true for the relevant AOD handlers; the selected setting alone is restored. |
| AOD Vibrancy | `IODeviceTree:/product` → `supports-aod-vibrancy`; compare with `DeviceSupportsAODVibrancy` | Restore true only when both checks pass. |
| Noise Exposure | `IODeviceTree:/product` → `env-audio-exp-capable`; compare with `DeviceSupportsEnvironmentalDosimetry` | Restore true only when both checks pass. |

For property-presence checks, an absent result may reflect restricted IORegistry access. The code therefore does not conclude that the native value is false solely from a missing property. Action Button is different: its false case requires a readable, well-formed list with known standard buttons and a matching MG answer. `24R359` is excluded from all system-derived recovery because its physical OTA layout has not been verified.

## Cannot be reconstructed from this evidence

`RegionInfo` and related region data are not covered by a safe fallback here. The OTA templates point to `syscfg/Regn`, which can differ between individual devices. The 115 model/build template observations were deliberately removed from the shipped defaults plist: the OTA reports are research evidence, not verified individual-device backups. A model table alone also cannot reliably recover the prior screen class when runtime display values differ from the template.

## Open validation work

- Confirm the private APIs and IORegistry properties are readable from the actual watch app process on each supported build and device family.
- Compare original values with the isolated-cache result on physical watches before any modifications, including native true and false cases.
- Verify post-write answers in the relevant consumer processes and after restart, and ensure unrelated cache entries remain unchanged.
- Exercise missing, malformed, mismatched, partial, and already-modified backups. Test a real overwrite update and reinstall separately before attributing data loss.
- Verify full OTA and layout provenance for `24R359` before allowing its native recovery paths.
