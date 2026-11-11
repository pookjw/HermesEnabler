# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler is an Apple Watch app that changes reported MobileGestalt capabilities and device properties. The iPhone companion app helps install and open the Watch app. Capability flags do not add physical hardware or grant unavailable services.

> Supported only on watchOS 27.0 through 27.3 beta 1.

![An Apple Watch showing a Hermès face](image.png)

## Build and run with Xcode

1. Install Xcode with iOS and watchOS SDKs. Connect an iPhone paired with the target Apple Watch, trust both devices, and enable Developer Mode if Xcode requests it.
2. Clone this repository and open `HermesEnabler2.xcodeproj`.
3. In **Signing & Capabilities**, select your Apple Development team for **HermesCompanion** and **HermesEnabler2**. Give `COMPANION_BUNDLE_IDENTIFIER` a unique iPhone bundle ID you control. The Watch app ID is that value plus `.watchkitapp`.
4. Configure the matching App Group for the targets and provisioning profiles. The Watch entitlements use `group.$(COMPANION_BUNDLE_IDENTIFIER)`; a missing App Group can prevent backup creation and MobileGestalt access.
5. Select the **HermesCompanion** scheme and the paired iPhone as the run destination, then choose **Product → Run**. If needed, open the iPhone Watch app and install HermesEnabler from **My Watch → Apps / Available Apps**.
6. Open HermesEnabler on the Watch and create the initial MobileGestalt backup. Keep a known-good backup before trying multiple changes.

For a compile-only check without signing:

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh` produces an **unsigned** iPhone IPA with the Watch app embedded. Sign both apps with suitable certificates and provisioning profiles before installation.

## Install a release IPA

Download an IPA from [Releases](https://github.com/pookjw/HermesEnabler/releases), install it using a method appropriate for your signing setup, then install the Watch app from the iPhone Watch app if needed.

## Features

This table reflects the current SwiftUI menus. Capability switches cannot add missing sensors, display hardware, audio hardware, or service eligibility.

| Item | Menu | Behavior and limits |
|---|---|---|
| Hermès | Watch Faces | Toggle the Hermès face capability; restart Carousel. |
| Ultra Faces | Watch Faces | Toggle Ultra face support; enabling it prevents use of the Hermès Faubourg Party face. Restart the Watch. |
| Always-On Display | Display & Controls | Change the reported always-on display capability. |
| AOD 1 Hz | Display & Controls | Change 1 Hz support; the face must support seconds in always-on mode. |
| AOD Vibrancy | Display & Controls | Change the always-on display vibrancy capability. |
| Periodic Ambient Light Updates | Display & Controls | Change the ambient-light update capability. |
| Screen Resolution | Display & Controls | Select a reported-size preset or restore the original; physical pixels do not change. Another size may clip content. Restart the Watch. |
| Action Button | Display & Controls | Change the reported Action Button capability; hardware is still required. |
| Double Tap | Display & Controls | Change the reported Double Tap capability. |
| On-Screen Keyboard | Display & Controls | Change the keyboard capability. |
| Raise Wrist to Wake | Display & Controls | Change the wrist-raise wake capability. |
| Raise to Speak | Display & Controls | Change the Raise to Speak capability. |
| Siri Listening Capability | Display & Controls | Change the listening capability; Siri settings and supported audio hardware still apply. |
| Depth Sensor | Sensors & Workouts | Change the depth-sensor capability; sensor hardware is still required. |
| Absolute Altimeter | Sensors & Workouts | Change the altimeter capability. |
| Always-On Compass | Sensors & Workouts | Change the compass capability. |
| Compass Orienteering | Sensors & Workouts | Change the orienteering capability. |
| Continuous Heart Rate | Sensors & Workouts | Change the heart-rate capability; sensor hardware and Health settings still apply. |
| Noise Exposure | Sensors & Workouts | Change the noise-exposure capability. |
| Battery Information | Sensors & Workouts | Change the battery-information capability. |
| Swimming Workouts | Sensors & Workouts | Change the swimming-workout capability. |
| Region Code | Siri & Intelligence | Change `RegionCode` only; leave the sales-region suffix unchanged. |
| Sales Region | Siri & Intelligence | Change the sales-region suffix only; factory-information tools may report a mismatch. |
| Apple Intelligence / Siri AI | Siri & Intelligence | Change the capability; the app requires watchOS 27, a supported Watch, and a paired Apple Intelligence iPhone for Siri AI. |
| On-Device Siri | Siri & Intelligence | Change the on-device Siri capability. |
| Audio Intelligence | Siri & Intelligence | Change the audio-intelligence capability; the app identifies Series 12 / Ultra 4 hardware as required. |
| Initial Backup | MG Backups | Create a protected initial backup that cannot be overwritten in the app. |
| Manual Backup | MG Backups | Back up the current MobileGestalt manually. |
| Automatic Backup | MG Backups | Back up MG before each write or restore. |
| Restore MG | MG Backups | Back up current MG, then restore a selected backup; non-initial backups can be deleted. Restart the Watch after restore. |
| Restart Carousel | Utilities | Restart the Watch UI process to reload relevant changes. |

The region and resolution menus offer presets. Errors and write-verification results appear in the app status area.

## Credits

This project incorporates code from [Gester](https://github.com/sasobhabha/Gester). Use at your own risk.
