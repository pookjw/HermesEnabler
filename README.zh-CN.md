# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> 仅支持 watchOS 27.0 至 27.3 beta 1。

## 安装

### macOS

在 macOS 上，你可以用 Sideloadly 安装预构建的 IPA，也可以直接用 Xcode 构建应用。两种方式都要求 iPhone 已与目标 Apple Watch 配对，且手表运行受支持的 watchOS 版本。

#### 安装 IPA

> **Sideloadly 0.72 已知问题：** [问题 #43](https://github.com/pookjw/HermesEnabler/issues/43) 报告称，该版本可能在签名时移除 IPA 内嵌的 Watch App。如果 iPhone App 已安装，但 Watch 上没有 HermesEnabler2，请改用 Xcode。此报告针对 0.72 版本，其他版本的兼容性尚未确认。

1. 从 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下载 IPA。
2. 在 Mac 上安装 [Sideloadly](https://sideloadly.io)，用数据线连接 iPhone，并在 Sideloadly 中选择该设备。
3. 将 IPA 拖入 Sideloadly 并输入 Apple ID。关闭 **Use automatic bundle ID**，指定固定的 Bundle Identifier，然后开始签名。
4. 在 iPhone 上打开 **设置 → 通用 → VPN 与设备管理**，信任你的开发者证书。
5. 在 iPhone 上打开 **设置 → 隐私与安全性 → 开发者模式**，开启、重启并确认。
6. 在 iPhone 的 **Watch App → 我的手表 → App** 中，将 **HermesEnabler2** 安装到手表。
7. 在 Apple Watch 上打开 **设置 → 隐私与安全性 → 开发者模式**，开启、重启并确认。如果没有显示该选项，请先安装手表 App，然后再次查看。
8. 在 Apple Watch 上打开 **HermesEnabler2**，并按照应用中的步骤操作。

#### 使用 Xcode 构建

你需要一台安装了兼容设备 iOS 和 watchOS 版本的 Xcode 的 Mac，以及已与 iPhone 配对的 Apple Watch。

1. 通过 **Code → Download ZIP** 下载并解压源代码，或克隆此仓库。在 Xcode 中打开 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)。
2. 在 **Xcode → Settings → Accounts**（或 **Apple Accounts**）中添加 Apple 账户。在 **TARGETS** 下，分别打开 **HermesEnabler2** 和 **HermesCompanion** 的 **Signing & Capabilities**，启用 **Automatically manage signing**，并为两者选择自己的同一个团队。
3. 选择蓝色项目图标，再打开 **PROJECT → HermesEnabler2 → Build Settings → All**。搜索 `COMPANION_BUNDLE_IDENTIFIER`，将 `com.example.HermesEnabler` 替换为自己的唯一标识符，为 **Debug** 和 **Release** 设置相同的值。保持各 target 现有的 Bundle Identifier 表达式不变。
4. 连接并解锁 iPhone，接受信任提示，让 Xcode 通过 **Device Hub** 或 **Window → Devices and Simulators** 检测 Watch。在两台设备上启用**设置 → 隐私与安全性 → 开发者模式**，重新启动并确认。如果没有该设置，请先让 Xcode 尝试连接，再检查设置。
5. 选择 **HermesEnabler2** scheme 和实体 **Apple Watch** 作为运行目标，然后点击 **▶ Run**。等待安装完成，在 Watch 上打开 **HermesEnabler2** 并按照应用中的步骤操作。**Build Succeeded** 表示编译完成，安装可能仍在进行。

> 如果 Device Hub 无法连接 Watch，有用户报告暂时关闭已配对 iPhone 的电源后重试会有所帮助。保持 Watch 解锁，并启用 Wi-Fi 和蓝牙；连接成功后再开启 iPhone。此方法不一定适用于所有配置。
>
> 有关 Personal Team 到期和 App Groups 签名限制，请参阅下方的**注意事项**。后续更新请继续使用相同的 Apple 账户和 Bundle Identifier。

### Windows

Windows 上使用 [WatchBridge](https://github.com/AdminZachary/iloader-for-windows)。它是一个社区工具，可准备开发者模式，并安装同时包含 iPhone 宿主应用和 Watch 应用的 IPA。它与 Apple 或本项目没有官方关联。

1. 安装 [iTunes](https://www.apple.com/itunes/) 或 Microsoft Store 中的 **Apple Devices** 应用，以获取 **Apple Mobile Device Service**。WatchBridge 的 USB 和 Wi-Fi 通信都依赖该服务。Windows 11 已内置 WebView2。
2. 确认 iPhone 已与目标 Apple Watch 配对。WatchBridge 一次仅支持一台已配对手表；如果配对了多台，准备步骤会停止，而不会猜测目标。
3. 从 [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest) 下载 `watchbridge-windows.zip`，解压并运行 `WatchBridge.exe`。该程序未签名，首次运行时 Windows SmartScreen 可能会提示。
4. 从 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下载 IPA。请使用同时包含 iPhone 宿主和 `Watch/*.app` 的原始 IPA；不支持仅含 Watch 的包。
5. 通过 USB 连接已配对的 iPhone，并在 WatchBridge 中选择该设备。
6. 配对手表，并在手表上确认信任提示。请求**开发者模式**开关后，在手表上打开 **设置 → 隐私与安全性 → 开发者模式**，开启、重启并确认。返回 WatchBridge 并点击 **Check again**。WatchBridge 不会替你开启开发者模式或重启手表。
7. 登录 Apple ID，选择 HermesEnabler2 的 IPA，然后开始签名与安装。WatchBridge 会先安装 iPhone 宿主应用，再安装手表应用。
8. 在 Apple Watch 上打开 **HermesEnabler2**，并按照应用中的步骤操作。

> 开发者模式准备需要 USB 连接。通过 USB 配对一次后，即可使用 Wi-Fi 安装和续签。

## 注意事项

- 在 Sideloadly 中关闭 **Use automatic bundle ID**，并使用固定的 Bundle Identifier。每次更新时都使用相同的 Bundle Identifier 和 Apple ID，以便保留现有应用数据和备份。
- 免费 Apple Personal Team 的配置描述文件会在 7 天后过期。过期后，请使用相同的 Apple ID 和 Bundle Identifier 重新构建并安装应用。
- 本项目使用 **App Groups** 权限，免费 Personal Team 无法为其配置签名。可能需要付费开发者团队；更改 Bundle Identifier 并不能消除此限制。不要认为移除此权限就一定能解决问题，因为尚未确认移除后应用的主要功能是否可用。
- 如果 iPhone App 已安装但 Watch App 没有出现，请在 Sideloadly 日志中查找 `Watch apps will be stripped from the IPA`。这表示内嵌的 Watch App 已被移除；请使用 Xcode 安装 Watch App。
- 删除应用前，请务必通过 HermesEnabler2 应用恢复 MobileGestalt 备份。

## 致谢

本项目包含来自 [Gester](https://github.com/sasobhabha/Gester) 的代码。

使用风险由您自行承担。
