# HermesEnabler 2

[English](README.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> watchOS 27.0から27.3 beta 1までのみ対応しています。

## インストール方法

### macOS

macOSでは、ビルド済みのIPAをWatchBridgeまたはSideloadlyでインストールするか、Xcodeで直接ビルドできます。iPhoneが対象のApple Watchとペアリングされ、Watchが対応するwatchOSバージョンで動作していることを確認してください。

#### IPAをインストール

> **Sideloadly 0.72の既知の問題:** [Issue #43](https://github.com/pookjw/HermesEnabler/issues/43)では、このバージョンが署名時にIPA内のWatchアプリを削除する場合があると報告されています。iPhoneアプリはインストールされたのにWatchにHermesEnabler2が表示されない場合は、Xcodeを使用してください。この報告は0.72に関するもので、他のバージョンとの互換性は確認されていません。

1. [Releases](https://github.com/pookjw/HermesEnabler/releases)からIPAをダウンロードします。
2. Macに[Sideloadly](https://sideloadly.io)をインストールし、ケーブルでiPhoneを接続してSideloadlyで選択します。
3. IPAをSideloadlyにドラッグし、Apple IDを入力します。**Use automatic bundle ID**をオフにして固定のBundle Identifierを指定し、署名を開始します。
4. iPhoneで**設定 → 一般 → VPNとデバイス管理**を開き、開発者証明書を信頼します。
5. iPhoneで**設定 → プライバシーとセキュリティ → デベロッパモード**を開いてオンにし、再起動して確認します。
6. iPhoneの**Watchアプリ → マイウォッチ → アプリ**から**HermesEnabler2**をWatchにインストールします。
7. Apple Watchで**設定 → プライバシーとセキュリティ → デベロッパモード**を開いてオンにし、再起動して確認します。項目が表示されない場合は、先にWatchアプリをインストールしてから再度確認してください。
8. Apple Watchで**HermesEnabler2**を開き、アプリの手順に従ってください。

#### Xcodeでビルド

1. Xcodeで[HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)を開きます。
2. 実行先にApple Watchを選択し、**Run**をクリックします。
3. Apple Watchで**HermesEnabler2**を開き、アプリの手順に従ってください。

#### WatchBridgeでインストール

macOS 11以降では、Xcodeをインストールせずにビルド済みのWatchBridgeのDMGを使用できます。

1. [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases)からMacに合ったDMGをダウンロードします。Apple Siliconは`arm64`、Intelは`x86_64`を選択します。DMGを開き、**WatchBridge.app**を**アプリケーション**フォルダにドラッグします。
2. [HermesEnabler Releases](https://github.com/pookjw/HermesEnabler/releases)から元のIPAをダウンロードします。ペアリング済みのiPhoneをUSBで接続し、WatchBridgeで選択します。
3. 画面の案内に従ってデベロッパモードのスイッチを表示します。Watch上でオンにし、再起動して確認します。その後、WatchBridgeでIPAに署名してインストールします。

初回起動時にmacOSでブロックされた場合は、WatchBridgeのリリースノートに従ってください。

### Windows

Windowsでは[WatchBridge](https://github.com/AdminZachary/iloader-for-windows)を使用します。WatchBridgeは、iPhoneホストアプリとWatchアプリの両方を含むIPAをインストールし、Apple Watchのデベロッパモードを準備するコミュニティツールです。Appleおよびこのプロジェクトとは公式な関係はありません。

1. [iTunes](https://www.apple.com/itunes/)またはMicrosoft Storeの**Apple Devices**アプリをインストールして、**Apple Mobile Device Service**を用意します。WatchBridgeはUSBとWi-Fiの通信にこのサービスを必要とします。WebView2はWindows 11に標準で含まれています。
2. iPhoneが対象のApple Watchとペアリングされていることを確認します。WatchBridgeが対応するペアリング済みWatchは1台のみで、複数ペアリングされている場合は推測せず準備を中止します。
3. [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest)から`watchbridge-windows.zip`をダウンロードして展開し、`WatchBridge.exe`を実行します。実行ファイルは署名されていないため、初回起動時にWindows SmartScreenの警告が表示される場合があります。
4. [Releases](https://github.com/pookjw/HermesEnabler/releases)からIPAをダウンロードします。iPhoneホストと`Watch/*.app`の両方を含む元のIPAを使用してください。Watch専用パッケージはサポートされません。
5. USBでペアリング済みのiPhoneを接続し、WatchBridgeでそのデバイスを選択します。
6. Watchをペアリングし、Watch上で信頼の確認を行います。**デベロッパモード**のスイッチを要求したら、Watchで**設定 → プライバシーとセキュリティ → デベロッパモード**を開いてオンにし、再起動して確認します。WatchBridgeに戻り、**Check again**をクリックします。WatchBridgeがデベロッパモードを有効化したりWatchを再起動したりすることはありません。
7. Apple IDでサインインし、HermesEnabler2のIPAを選択して署名とインストールを開始します。WatchBridgeはiPhoneホストアプリを先にインストールし、その後Watchアプリをインストールします。
8. Apple Watchで**HermesEnabler2**を開き、アプリの手順に従ってください。

> デベロッパモードの準備にはUSB接続が必要です。USBで一度ペアリングした後は、Wi-Fiでインストールと更新を行えます。

## 注意事項

- Sideloadlyで**Use automatic bundle ID**をオフにし、固定のBundle Identifierを使用してください。既存のアプリデータとバックアップを引き継ぐため、アップデート時は毎回同じBundle IdentifierとApple IDを使用してください。
- 無料のApple Personal Teamのプロビジョニングプロファイルは7日で期限切れになります。期限切れ後は、同じApple IDとBundle Identifierを使ってアプリを再ビルド・再インストールしてください。
- このプロジェクトは**App Groups**エンタイトルメントを使用しており、無料のPersonal Teamではプロビジョニングできません。有料の開発者チームが必要になる場合があります。Bundle Identifierを変更してもこの制限は解消されず、エンタイトルメントを削除した場合に主要機能が動作するかも確認されていません。
- iPhoneアプリはインストールされたのにWatchアプリが表示されない場合は、Sideloadlyのログで`Watch apps will be stripped from the IPA`を確認してください。これはIPA内のWatchアプリが削除されたことを示します。XcodeでWatchアプリをインストールしてください。
- アプリを削除する前に、必ずHermesEnabler2アプリからMobileGestaltのバックアップを復元してください。

## クレジット

このプロジェクトには[Gester](https://github.com/sasobhabha/Gester)のコードが含まれています。

ご自身の責任でご使用ください。
