# Experimental Apple-original Hermès FaceViews on watchOS 26

## Purpose

Provide an **opt-in in-app viewer** for six genuine FaceViews loaded from Apple's **installed** NanoTimeKit FaceBundles. Unlike the existing HermesEnabler2 MobileGestalt toggle, this feature can open even when a valid MG sandbox token is unavailable. No hand-drawn clock, screenshot-based face, distributed Apple binaries, or changes to the system Face Gallery are involved.

**This does not unlock the first-party Apple ClockFace or replace the watchOS system face.** The UI says so explicitly.

## Build and simulator validation (2026-11-16)

- Base: upstream HermesEnabler2 1.6.1, commit `a4feb9071`.
- Xcode 27.3: watchOS SDK and watchOS Simulator SDK **build succeeded** with signing disabled.
- Simulator: Apple Watch Series 6 (Watch6,2), watchOS 26.5, separate experimental bundle ID.
- Six independent simulator launches using the explicit DEBUG-only `--native-smoke-index N` argument.
- In all six cases, the Apple original native class matched the expected Face/View types and the native FaceView was attached to the application's actual window. The smoke log reported `native-face-mounted`.
- Six simulator screenshots were visually inspected locally. They showed genuine face visuals for Circulaire (Poodle), Hermès (Zeus Analog), Radial (Bellona), Circuit H (Hades), Lucky Horse (Secretariat), and Faubourg Party (Hermes2025).
- **No simulator screenshot or extracted Apple resource is committed to this repository.**

For a debug-only simulator smoke check after building and installing the watch app, launch with:

```sh
xcrun simctl launch --terminate-running-process <simulator-id> <watch-bundle-id> --native-smoke-index 2
```

Look for `[BQ_NATIVE_SMOKE]` in the simulator unified log. A successful mount does not prove every complication, AOD transition, or first-party feature works.

## Separate physical-watch research — NOT a test of this integrated patch

A separate, locally maintained original-Apple-components research app has physically mounted all six genuine Apple FaceViews on a non-Hermès Apple Watch Series 6 Cellular (Watch6,4), stock watchOS 26.6 (23U67). That experiment includes real reduced-luminance events and native Apple tritium/backlight objects, but does not have first-party ClockFace privileges.

On the same watch, untouched upstream HermesEnabler2 1.6.1, built and signed with a working App Group, installed and launched. Its Hermès switch failed to enable. A fresh log of 129 escape attempts showed **zero usable sandbox tokens**, including `class13-bad-query`. The printed `consume=-5` is the app's fallback when no token exists, not a returned sandbox consume error. The protected MG cache was **not modified**.

Other devices have reportedly obtained a system-group token with alternative MCM flags but still received `EPERM` trying to write MobileGestalt. Token acquisition is not equivalent to authorization for MG writes.

## Known limitations

1. This exact upstream integration has **not yet been installed on the physical Series 6**; the validated integrated runtime above is a watchOS 26.5 simulator. The physical six-face result belongs to the separate research app.
2. The first-party system Face Gallery, system face switching, and ClockFace process identity remain unchanged. In-app swiping, activation and system persistence are not equivalent to these features.
3. The extra watchOS in-app status time appears above the native view in simulator screenshots. No verified mechanism for hiding that system overlay is claimed.
4. Native Apple complications requiring `com.apple.chrono.WidgetRenderer-Default` can remain blank in third-party apps: a separate experiment observed a RunningBoard `Client not authorized` error. This PR does not bypass renderer authorization.
5. Genuine Apple tritium/backlight APIs are used without synthetic face artwork, but identical first-party AOD timing, wrist transitions and indefinite foreground retention are **not proven**.
6. Private Apple frameworks and method signatures may change by watchOS build, so the feature is restricted to watchOS 26; any unsupported method or original FaceView failure should stop without substituting an imitation.

## Safety and review scope

- All six faces are obtained from Apple-installed system frameworks at runtime, not copied into this repository.
- The temporary `CLKDevice.collectionType` change applies only to the app process and is restored in `@finally`; no global watch identity, MobileGestalt, FaceCollection, or system ClockFace write is requested.
- The feature remains available from the MG backup screen even if MobileGestalt backup/access fails.
- No App Group entitlement, signing identity, raw user backup, identifying device log, or Apple proprietary binary is included.
- The path is exposed as **Experimental**, intended for iterative review rather than claiming a full watchOS 26 unlock.

Further physical testing and owner review are welcome. The separate first-party system-face unlock remains blocked by protected MG write and ClockFace admission constraints.
