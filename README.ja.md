# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> watchOS 27.0から27.3 beta 1までのみ対応しています。

## インストール方法

### macOS

macOSでは、ビルド済みのIPAをSideloadlyでインストールするか、Xcodeで直接ビルドできます。どちらの方法でも、iPhoneが対象のApple Watchとペアリングされていて、Watchが対応するwatchOSバージョンで動作している必要があります。

#### IPAをインストール

1. [Releases](https://github.com/pookjw/HermesEnabler/releases)からIPAをダウンロードします。
2. Macに[Sideloadly](https://sideloadly.io)をインストールし、ケーブルでiPhoneを接続してSideloadlyで選択します。
3. IPAをSideloadlyにドラッグし、Apple IDを入力します。**Use automatic bundle ID**をオフにして固定のBundle Identifierを指定し、署名を開始します。
4. iPhoneで**設定 → 一般 → VPNとデバイス管理**を開き、開発者証明書を信頼します。
5. iPhoneで**設定 → プライバシーとセキュリティ → デベロッパモード**を開いてオンにし、再起動して確認します。
6. iPhoneの**Watchアプリ → マイウォッチ → アプリ**から**HermesEnabler2**をWatchにインストールします。
7. Apple Watchで**設定 → プライバシーとセキュリティ → デベロッパモード**を開いてオンにし、再起動して確認します。項目が表示されない場合は、先にWatchアプリをインストールしてから再度確認してください。
8. Apple Watchで**HermesEnabler2**を開き、アプリの手順に従ってください。

#### Xcodeでビルド

デバイスのiOSとwatchOSのバージョンに対応するXcodeを搭載したMacと、iPhoneにペアリング済みのApple Watchが必要です。

1. **Code → Download ZIP**からソースコードをダウンロードして展開するか、このリポジトリをクローンします。Xcodeで[HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)を開きます。
2. **Xcode → Settings → Accounts**（または**Apple Accounts**）でApple Accountを追加します。**TARGETS**の**HermesEnabler2**と**HermesCompanion**でそれぞれ**Signing & Capabilities**を開き、**Automatically manage signing**を有効にして、両方に自分の同じチームを選択します。
3. 青いプロジェクトアイコンを選び、**PROJECT → HermesEnabler2 → Build Settings → All**を開きます。`COMPANION_BUNDLE_IDENTIFIER`を検索し、`com.example.HermesEnabler`を自分用の一意な識別子に変更します。**Debug**と**Release**には同じ値を設定し、各ターゲットの既存のBundle Identifier式は変更しないでください。
4. iPhoneを接続してロックを解除し、信頼の確認に応答します。**Device Hub**または**Window → Devices and Simulators**でXcodeにWatchを検出させます。両方のデバイスで**設定 → プライバシーとセキュリティ → デベロッパモード**を有効にし、再起動して確認します。設定がない場合は、先にXcodeから接続を試みてから再度確認してください。
5. **HermesEnabler2**スキームと実機の**Apple Watch**を実行先に選び、**▶ Run**をクリックします。インストールが完了したらWatchで**HermesEnabler2**を開き、アプリの手順に従ってください。**Build Succeeded**はコンパイル完了を意味し、インストールはまだ続いている場合があります。

> Device HubがWatchに接続できない場合、ペアリング済みのiPhoneの電源を一時的に切って再試行すると改善したという報告があります。Watchのロックを解除し、Wi-FiとBluetoothを有効にしたままにして、接続後にiPhoneの電源を入れ直してください。この回避策がすべての環境で有効とは限りません。
>
> Personal Teamの有効期限とApp Groupsの署名制限については、下の**注意事項**を参照してください。今後の更新でも同じApple AccountとBundle Identifierを使用してください。

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
- **App Groups**エンタイトルメントのため、有料のApple Developerアカウントが必要です。
- iPhoneアプリはインストールされたのにWatchアプリが表示されない場合は、Sideloadlyのログで`Watch apps will be stripped from the IPA`を確認してください。これはIPA内のWatchアプリが削除されたことを示します。XcodeでWatchアプリをインストールしてください。
- アプリを削除する前に、必ずHermesEnabler2アプリからMobileGestaltのバックアップを復元してください。

## クレジット

このプロジェクトには[Gester](https://github.com/sasobhabha/Gester)のコードが含まれています。

ご自身の責任でご使用ください。
