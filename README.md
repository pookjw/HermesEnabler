# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Supported only on watchOS 27.0 through 27.3 beta 1.

## Installation

### Build with Xcode

#### Before you begin

You will need:

- A Mac with a version of Xcode that supports your devices’ iOS and watchOS versions.
- An Apple Watch paired with your iPhone.
- An Apple Account added to Xcode.
- The project’s source code. Download and extract **Code → Download ZIP**, or clone this repository.

Xcode is the recommended installation method here because a problem with installing the Watch app through Sideloadly 0.72 has been reported in [issue #43](https://github.com/pookjw/HermesEnabler/issues/43). The alternative IPA instructions are retained below.

#### 1. Add your Apple Account to Xcode

1. Open **Xcode → Settings → Accounts** or **Apple Accounts**, depending on your Xcode version.
2. Click **+** and sign in with your Apple Account.
3. If you do not have a paid Apple Developer Program membership, your account appears as **Your Name (Personal Team)**.

“Team” identifies the Apple developer account used to sign the app. You do not need to join the project author’s team.

A Personal Team allows installation of development apps, but has limitations, including profile expiration and unsupported capabilities. See **Signing limitations and troubleshooting** below.

#### 2. Connect your iPhone and enable Developer Mode

1. Connect your iPhone to your Mac.
2. Unlock it and accept **Trust This Computer** if prompted.
3. Open Xcode’s device manager: **Device Hub** in newer versions, or **Window → Devices and Simulators** in older versions.
4. Let Xcode recognize your iPhone.
5. On your iPhone, open **Settings → Privacy & Security → Developer Mode**.
6. Enable Developer Mode and accept the restart.
7. After restarting, unlock your iPhone and confirm that you want to enable Developer Mode.

If the Developer Mode setting is missing, first establish the connection with Xcode, then check Settings again.

#### 3. Connect your Apple Watch and enable Developer Mode

1. Keep your Watch unlocked and near your Mac and iPhone.
2. Let Xcode discover the Watch. In Device Hub, use the option to add or pair a nearby device if necessary.
3. Accept any connection or trust prompts on your devices.
4. On the Watch itself, open **Settings → Privacy & Security → Developer Mode**.
5. Enable Developer Mode and accept the restart.
6. After restarting, unlock the Watch and confirm any request to enable Developer Mode.
7. Reconnect the Watch in Xcode if necessary.

The Watch’s Developer Mode setting may not appear until Xcode has attempted to connect to it. If it is missing, establish the initial connection and check the Watch’s Settings again.

For background, see Apple’s [Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

##### If Device Hub cannot pair with the Watch

If pairing or connecting fails while the paired iPhone is powered on, try this workaround:

1. Complete the iPhone setup above first.
2. Temporarily **power off the iPhone**.
3. Leave the Watch powered on and unlocked, with Wi-Fi and Bluetooth enabled.
4. Retry pairing or connecting the Watch in **Device Hub/Xcode**.
5. Accept any connection prompts on the Watch.
6. Once the Watch connects, turn the iPhone back on.

This workaround has been reported to help in some setups. The iPhone being powered on is not a confirmed cause of all Watch pairing problems, and this procedure may not resolve every connection issue.

#### 4. Configure signing and a unique bundle identifier

1. Open `HermesEnabler2.xcodeproj`.
2. Select the blue project icon in Xcode’s project navigator.
3. Under **PROJECT**, select **HermesEnabler2**.
4. Open **Build Settings**, select **All**, and search for:
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. Replace `com.example.HermesEnabler` with your own unique identifier, for example:
   ```
   com.yourname.HermesEnabler12345
   ```
6. Apply the same value to **Debug** and **Release**.
7. Under **TARGETS**, select **HermesEnabler2** and open **Signing & Capabilities**.
8. Enable **Automatically manage signing** and select your team.
9. Repeat the signing settings for **HermesCompanion**, selecting the same team.

Leave the targets’ existing bundle identifier expressions unchanged:

| Target | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

The project uses the shared setting to keep the iPhone and Watch identifiers consistent.

If Xcode reports **Failed Registering Bundle Identifier** or says the identifier is unavailable, choose a more distinctive `COMPANION_BUNDLE_IDENTIFIER`. Return to **Signing & Capabilities** and click **Try Again** if that button appears.

If an App Groups error remains, see **App Groups errors** below.

#### 5. Build and run on your Watch

1. Select the **HermesEnabler2** scheme.
2. Choose your physical **Apple Watch** as the run destination.
3. Click **▶ Run**.
4. Allow Xcode to finish preparing the device and installing the app.
5. Once HermesEnabler2 opens on your Watch, follow the instructions in the app.

**Build Succeeded** means compilation finished successfully. Installation may still be in progress.

If Xcode displays **Installing built products**, wait for installation to complete. Keep your devices nearby and connected.

A debugging session can remain active while the app runs; this is normal. Check the Watch’s screen to see whether the app has opened.

### Alternative: Install the IPA with Sideloadly

> **Known issue with Sideloadly 0.72:** [Issue #43](https://github.com/pookjw/HermesEnabler/issues/43) reports that this version removes the embedded watchOS app during signing. The iPhone app installs, but HermesEnabler2 does not appear on the Apple Watch or in the iPhone’s Watch app. If you encounter this problem, use the **Build with Xcode** instructions above.
>
> This report concerns version 0.72. Compatibility with other Sideloadly versions has not been confirmed here.

1. Download `HermesEnabler.ipa` from [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Open [Sideloadly](https://sideloadly.io).
3. Disable **Use automatic bundle ID** and choose a fixed, unique Bundle Identifier.
4. Install the IPA on your iPhone.
5. On your iPhone, open **Watch → My Watch → Apps** and look for **HermesEnabler2** under **Available Apps**.
6. If it appears, install it on your Watch, then open it and follow the instructions in the app.
7. If it does not appear, use Xcode to install the Watch app.

Keep the same Bundle Identifier and Apple Account for subsequent updates so the app can retain its existing data and backup.

## Signing limitations and troubleshooting

### Personal Team expiration

Free Personal Team provisioning profiles expire after seven days. Rebuild and reinstall the app through Xcode when the profile expires.

Keep using the same Apple Account and bundle identifier for updates.

### App Groups errors

This project includes an **App Groups** entitlement. A free Personal Team does not support provisioning this capability.

If Xcode reports that an App Group is unavailable:

- Check that `COMPANION_BUNDLE_IDENTIFIER` has been changed to a unique value.
- If you have a paid developer membership, select that team and ensure the corresponding App Group can be registered.
- Changing the identifier does not remove a Personal Team’s capability limitations.

Do not assume that removing App Groups is a complete solution. Issue #43 reports successful installation through Xcode, but does not confirm that the MobileGestalt operation works without App Groups on watchOS 27.2.1.

A successful build or installation alone does not establish that the app’s main functionality works.

### The iPhone app installs, but the Watch app is missing

If you used Sideloadly 0.72, check its log for:

```
Watch apps will be stripped from the IPA
```

This indicates that the embedded Watch app was removed. Installing the iPhone app alone will not make the missing Watch app available. Follow the Xcode installation instructions above.

## Cautions

- Keep the same bundle identifier and Apple Account for updates so the app can retain its existing data and backup.
- Before deleting the app, always restore your MobileGestalt backup through HermesEnabler2.

## Credits

This project incorporates code from [Gester](https://github.com/sasobhabha/Gester).

Use at your own risk.
