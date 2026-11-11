# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> watchOS 27.0から27.3 beta 1までのみ対応しています。

## インストール方法

### IPAをインストール

1. [Releases](https://github.com/pookjw/HermesEnabler/releases)からIPAをダウンロードします。
2. [Sideloadly](https://sideloadly.io)を使ってインストールします。
3. iPhoneの**Watchアプリ → マイウォッチ → アプリ**から**HermesEnabler2**をインストールします。
4. Apple Watchで**HermesEnabler2**を開き、アプリの手順に従ってください。

> Sideloadlyで**Use automatic bundle ID**をオフにし、固定のBundle Identifierを使用してください。既存のアプリデータとバックアップを引き継ぐため、アップデート時は毎回同じBundle IdentifierとApple IDを使用してください。

> アプリを削除する前に、必ずMobileGestaltのバックアップを復元してください。

### Xcodeでビルド

1. Xcodeで[HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)を開きます。
2. 実行先にApple Watchを選択し、**Run**をクリックします。
3. Apple Watchで**HermesEnabler2**を開き、アプリの手順に従ってください。

## クレジット

このプロジェクトには[Gester](https://github.com/sasobhabha/Gester)のコードが含まれています。

ご自身の責任でご使用ください。
