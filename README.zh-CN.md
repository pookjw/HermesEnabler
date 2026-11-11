# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> 仅支持 watchOS 27.0 至 27.3 beta 1。

## 安装

### 安装 IPA

1. 从 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下载 IPA。
2. 使用 [Sideloadly](https://sideloadly.io) 安装。
3. 在 iPhone 上打开 **Watch（手表）App → 我的手表 → App**，安装 **HermesEnabler2**。
4. 在 Apple Watch 上打开 **HermesEnabler2**，并按照应用中的步骤操作。

> 在 Sideloadly 中关闭 **Use automatic bundle ID**，并使用固定的 Bundle Identifier。每次更新时都使用相同的 Bundle Identifier 和 Apple ID，以便保留现有应用数据和备份。

> 删除应用前，请务必通过 HermesEnabler2 应用恢复 MobileGestalt 备份。

### 使用 Xcode 构建

1. 在 Xcode 中打开 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)。
2. 选择 Apple Watch 作为运行目标，然后点击 **Run**。
3. 在 Apple Watch 上打开 **HermesEnabler2**，并按照应用中的步骤操作。

## 致谢

本项目包含来自 [Gester](https://github.com/sasobhabha/Gester) 的代码。

使用风险由您自行承担。
