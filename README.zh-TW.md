# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> 僅支援 watchOS 27.0 至 27.3 beta 1。

## 安裝

### 安裝 IPA

1. 從 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下載 IPA。
2. 使用 [Sideloadly](https://sideloadly.io) 安裝。
3. 在 iPhone 上打開 **Watch（手錶）App → 我的手錶 → App**，安裝 **HermesEnabler2**。
4. 在 Apple Watch 上打開 **HermesEnabler2**，並依照 app 中的步驟操作。

> 在 Sideloadly 中關閉 **Use automatic bundle ID**，並使用固定的 Bundle Identifier。每次更新時都使用相同的 Bundle Identifier 和 Apple ID，以便保留現有的 App 資料和備份。

> 刪除 App 前，請務必還原 MobileGestalt 備份。

### 使用 Xcode 建置

1. 在 Xcode 中打開 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)。
2. 選擇 Apple Watch 作為執行目標，然後點擊 **Run**。
3. 在 Apple Watch 上打開 **HermesEnabler2**，並依照 app 中的步驟操作。

## 致謝

本專案包含來自 [Gester](https://github.com/sasobhabha/Gester) 的程式碼。

使用風險由您自行承擔。
