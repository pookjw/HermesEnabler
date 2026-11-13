# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

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

You need a Mac with an Xcode version that supports your devices’ iOS and watchOS versions, and an Apple Watch paired with your iPhone.

1. Download and extract the source code using **Code → Download ZIP**, or clone this repository. Open [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) in Xcode.
2. Add your Apple Account under **Xcode → Settings → Accounts** (or **Apple Accounts**). Under **TARGETS**, open **Signing & Capabilities** for both **HermesEnabler2** and **HermesCompanion**, enable **Automatically manage signing**, and select your own team for each.
3. Select the blue project icon, then **PROJECT → HermesEnabler2 → Build Settings → All**. Search for `COMPANION_BUNDLE_IDENTIFIER` and replace `com.example.HermesEnabler` with a unique identifier of your own for both **Debug** and **Release**. Leave the targets’ existing Bundle Identifier expressions unchanged.
4. Connect and unlock your iPhone, accept any trust prompts, and let Xcode detect your Watch through **Device Hub** or **Window → Devices and Simulators**. On both devices, enable **Settings → Privacy & Security → Developer Mode**, restart, and confirm. If the setting is missing, first let Xcode attempt to connect, then check again.
5. Select the **HermesEnabler2** scheme and your physical **Apple Watch** as the run destination, then click **▶ Run**. Wait for installation to finish, open **HermesEnabler2** on the Watch, and follow the steps in the app. **Build Succeeded** means compilation finished; installation may still be running.

> If Device Hub cannot connect to the Watch, temporarily powering off the paired iPhone and retrying has helped some users. Keep the Watch unlocked with Wi-Fi and Bluetooth enabled, and turn the iPhone back on after connecting. This workaround may not help every setup.
>
> See **Cautions** below for Personal Team expiration and App Groups signing limitations. Keep the same Apple Account and Bundle Identifier for future updates.

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
- A paid Apple Developer account is required due to the **App Groups** entitlement.
- If the iPhone app installs but the Watch app does not appear, check the Sideloadly log for `Watch apps will be stripped from the IPA`. This means the embedded Watch app was removed; installing the iPhone app alone will not install it. Use Xcode to install the Watch app.
- Before deleting the app, always restore your MobileGestalt backup through the HermesEnabler2 app.

## Credits

This project incorporates code from [Gester](https://github.com/sasobhabha/Gester).

Use at your own risk.
