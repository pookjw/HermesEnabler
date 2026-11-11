# HermesEnabler 2
[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnablerは、Apple Watchが報告するMobileGestaltの機能とデバイス情報を変更するアプリです。iPhone用のコンパニオンアプリからWatchアプリをインストールできます。機能フラグで不足しているハードウェアや利用資格を追加することはできません。

> watchOS 27.0から27.3 beta 1までのみ対応しています。

![Apple Watch](image.png)

## Xcodeでビルドしてインストール

1. iOSとwatchOSのSDKを含むXcodeをインストールします。対象のApple Watchとペアリング済みのiPhoneを接続して信頼し、Xcodeから求められた場合はデベロッパモードを有効にします。
2. リポジトリをクローンし、Xcodeで`HermesEnabler2.xcodeproj`を開きます。
3. **Signing & Capabilities**で**HermesCompanion**と**HermesEnabler2**に自分のApple Developmentチームを設定します。`COMPANION_BUNDLE_IDENTIFIER`を自分が管理する一意のiPhone Bundle IDに変更します。WatchアプリのIDには`.watchkitapp`が付きます。
4. 両ターゲットとプロビジョニングプロファイルに対応するApp Groupを設定します。Watchのentitlementは`group.$(COMPANION_BUNDLE_IDENTIFIER)`を使用します。App GroupがないとMobileGestaltへのアクセスやバックアップに失敗することがあります。
5. **HermesCompanion**スキームとペアリング済みiPhoneを選び、**Product → Run**を実行します。Watchアプリが自動で入らない場合は、iPhoneのWatchアプリの**マイウォッチ → アプリ／利用可能なアプリ**からインストールします。
6. Apple WatchでHermesEnablerを開き、最初のMobileGestaltバックアップを作成します。複数の設定を試す前に、正常なバックアップを残してください。

署名せずにコンパイルだけ確認する場合：

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh`はWatchアプリを含む**未署名**のiPhone IPAを作成します。インストールする前に、両アプリを適切な証明書とプロファイルで署名してください。

## リリースIPAのインストール

[Releases](https://github.com/pookjw/HermesEnabler/releases)からIPAを入手し、使用する署名設定に応じた方法でインストールします。必要に応じてiPhoneのWatchアプリからWatchアプリを追加します。

## 機能一覧

| 項目 | メニュー | 動作と制限 |
|---|---|---|
| Hermès | 文字盤 | 報告される「Hermès」を切り替えます。 |
| Ultra文字盤 | 文字盤 | Ultra文字盤を切り替えます。有効にするとHermès Faubourg Party文字盤は使えません。Watchを再起動してください。 |
| 常にオン | ディスプレイとコントロール | 報告される「常にオン」を切り替えます。 |
| 常にオン 1 Hz | ディスプレイとコントロール | 報告される「常にオン 1 Hz」を切り替えます。 |
| 常にオンの鮮やかさ | ディスプレイとコントロール | 報告される「常にオンの鮮やかさ」を切り替えます。 |
| 環境光の定期更新 | ディスプレイとコントロール | 報告される「環境光の定期更新」を切り替えます。 |
| 画面解像度 | ディスプレイとコントロール | 報告される画面サイズを選択または復元します。物理ピクセルは変わらず、表示が切れる場合があります。Watchを再起動してください。 |
| アクションボタン | ディスプレイとコントロール | 報告される「アクションボタン」を切り替えます。 |
| ダブルタップ | ディスプレイとコントロール | 報告される「ダブルタップ」を切り替えます。 |
| オンスクリーンキーボード | ディスプレイとコントロール | 報告される「オンスクリーンキーボード」を切り替えます。 |
| 手首を上げてスリープ解除 | ディスプレイとコントロール | 報告される「手首を上げてスリープ解除」を切り替えます。 |
| 手首を上げて話す | ディスプレイとコントロール | 報告される「手首を上げて話す」を切り替えます。 |
| Siriの聞き取り機能 | ディスプレイとコントロール | 報告される「Siriの聞き取り機能」を切り替えます。 |
| 水深センサー | センサーとワークアウト | 報告される「水深センサー」を切り替えます。 |
| 絶対高度計 | センサーとワークアウト | 報告される「絶対高度計」を切り替えます。 |
| 常時表示コンパス | センサーとワークアウト | 報告される「常時表示コンパス」を切り替えます。 |
| コンパスのオリエンテーリング | センサーとワークアウト | 報告される「コンパスのオリエンテーリング」を切り替えます。 |
| 継続的な心拍数測定 | センサーとワークアウト | 報告される「継続的な心拍数測定」を切り替えます。 |
| 騒音への曝露 | センサーとワークアウト | 報告される「騒音への曝露」を切り替えます。 |
| バッテリー情報 | センサーとワークアウト | 報告される「バッテリー情報」を切り替えます。 |
| スイミングワークアウト | センサーとワークアウト | 報告される「スイミングワークアウト」を切り替えます。 |
| 地域コード | Siri とインテリジェンス | RegionCodeのみ変更し、販売地域のサフィックスは変更しません。 |
| 販売地域 | Siri とインテリジェンス | 販売地域のサフィックスのみ変更します。製造情報ツールで不一致になる場合があります。 |
| Apple Intelligence / Siri AI | Siri とインテリジェンス | 機能を切り替えます。Siri AIにはwatchOS 27、対応Watch、ペアリング済みのApple Intelligence対応iPhoneが必要です。 |
| オンデバイスSiri | Siri とインテリジェンス | 報告される「オンデバイスSiri」を切り替えます。 |
| オーディオインテリジェンス | Siri とインテリジェンス | オーディオインテリジェンス機能を切り替えます。アプリではSeries 12／Ultra 4のハードウェアが必要とされています。 |
| 初期バックアップ | MG バックアップ | 上書きできない初期バックアップを作成します。 |
| 手動バックアップ | MG バックアップ | 現在のMobileGestaltを手動でバックアップします。 |
| 自動バックアップ | MG バックアップ | MGの書き込みと復元の前に自動でバックアップします。 |
| MGを復元する | MG バックアップ | 現在のMGをバックアップしてから選択したバックアップを復元します。Watchを再起動してください。 |
| Carouselを再起動します | ユーティリティ | Watchの画面プロセスを再起動して変更を反映します。 |

機能フラグは不足しているディスプレイ、センサー、オーディオハードウェアやサービスの利用資格を追加しません。地域と画面解像度にはプリセットがあります。書き込みエラーはアプリ内に表示されます。

## クレジット

このプロジェクトには[Gester](https://github.com/sasobhabha/Gester)のコードが含まれています。ご自身の責任でご使用ください。
