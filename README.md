# HermesEnabler 2

![](image.png)
## iPhone companion and Apple Watch installation

The `HermesCompanion` scheme builds an iPhone app containing the watch app. Install the iPhone app, then open the Watch app on the paired iPhone and install HermesEnabler under Available Apps if it was not installed automatically. Automatic installation depends on the user's Watch settings.

Before building for a device or uploading to App Store Connect:

1. Select your development team for both targets in Xcode's Signing & Capabilities.
2. Change `COMPANION_BUNDLE_IDENTIFIER` at the project level to an identifier owned by your team. The watch bundle identifier and companion reference use this value automatically.
3. Register the App Group `group.<COMPANION_BUNDLE_IDENTIFIER>` with your team and enable it for the watch target. App Group access is used by one of the watch app's available methods; signing without it can limit functionality.
4. Archive the `HermesCompanion` scheme for an iOS device. The standalone watch scheme remains available for development, but this configuration builds the watch app as a companion app.

The companion provides installation guidance; the Hermes functionality runs on the watch.
