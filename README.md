# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Supported only on watchOS 27.0 through 27.3 beta 1.

## Installation

### macOS

On macOS you can install the prebuilt IPA with Sideloadly or build the app directly with Xcode. Either way, the iPhone must be paired with the target Apple Watch, and the Watch must run a supported watchOS version.

#### Install the IPA

1. Download the IPA from [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Install [Sideloadly](https://sideloadly.io) on your Mac, connect your iPhone with a cable, and select it in Sideloadly.
3. Drag the IPA into Sideloadly and enter your Apple ID. Turn off **Use automatic bundle ID**, set a fixed Bundle Identifier, and start signing.
4. On the iPhone, open **Settings → General → VPN & Device Management** and trust your developer certificate.
5. On the iPhone, open **Settings → Privacy & Security → Developer Mode**, turn it on, restart, and confirm.
6. On the iPhone, open the **Watch** app, go to **My Watch → Apps**, and install **HermesEnabler2** on the Watch.
7. On the Apple Watch, open **Settings → Privacy & Security → Developer Mode**, turn it on, restart, and confirm. If the option is not shown, install the Watch app first and check again.
8. Open **HermesEnabler2** on your Apple Watch and follow the steps in the app.

#### Build with Xcode

1. Open [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) in Xcode.
2. Select your Apple Watch as the run destination and click **Run**.
3. Open **HermesEnabler2** on your Apple Watch and follow the steps in the app.

### Windows

Windows uses [WatchBridge](https://github.com/AdminZachary/iloader-for-windows), a community tool that prepares Developer Mode and installs an IPA containing both an iPhone host app and a Watch app. It is not affiliated with Apple or with this project.

1. Install **Apple Mobile Device Service** by installing [iTunes](https://www.apple.com/itunes/) or the **Apple Devices** app from the Microsoft Store. WatchBridge needs it for USB and Wi-Fi communication. WebView2 is built into Windows 11.
2. Make sure your iPhone is paired with the target Apple Watch. WatchBridge supports only one paired Watch at a time; if more than one is paired, the preparation step stops instead of guessing.
3. Download `watchbridge-windows.zip` from [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest), extract it, and run `WatchBridge.exe`. The executable is unsigned, so Windows SmartScreen may warn on first launch.
4. Download the IPA from [Releases](https://github.com/pookjw/HermesEnabler/releases). Use the original IPA that contains both the iPhone host and the `Watch/*.app`; Watch-only packages are not supported.
5. Connect the paired iPhone over USB and select it in WatchBridge.
6. Pair the Watch and confirm the trust prompt on the Watch. Request the **Developer Mode** switch, then on the Watch open **Settings → Privacy & Security → Developer Mode**, turn it on, restart, and confirm. Return to WatchBridge and click **Check again**. WatchBridge does not enable Developer Mode or restart the Watch for you.
7. Sign in with your Apple ID, select the HermesEnabler2 IPA, and start signing and installation. WatchBridge installs the iPhone host app first, then the Watch app.
8. Open **HermesEnabler2** on your Apple Watch and follow the steps in the app.

> Developer-mode preparation requires a USB connection. After pairing over USB once, installs and renewals can use Wi-Fi.

## Cautions

- In Sideloadly, disable **Use automatic bundle ID** and use a fixed Bundle Identifier. Keep the same Bundle Identifier and Apple ID for every update so the app can retain its existing data and backup.
- Before deleting the app, always restore your MobileGestalt backup through the HermesEnabler2 app.

## Credits

This project incorporates code from [Gester](https://github.com/sasobhabha/Gester).

Use at your own risk.
