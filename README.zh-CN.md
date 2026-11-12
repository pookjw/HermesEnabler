# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> 仅支持 watchOS 27.0 至 27.3 beta 1。

## 安装

### 使用 Xcode 构建

#### 准备工作

你需要：

- 一台 Mac，安装支持设备当前 iOS 和 watchOS 版本的 Xcode。
- 已与 iPhone 配对的 Apple Watch。
- 已添加到 Xcode 的 Apple 账户。
- 项目源代码。通过 **Code → Download ZIP** 下载并解压，或克隆此仓库。

[问题 #43](https://github.com/pookjw/HermesEnabler/issues/43) 报告了 Sideloadly 0.72 安装 Watch App 时的问题，因此这里推荐使用 Xcode。下方仍保留 IPA 安装方式。

#### 1. 将 Apple 账户添加到 Xcode

1. 根据 Xcode 版本，打开 **Xcode → Settings → Accounts** 或 **Apple Accounts**。
2. 点击 **+**，使用 Apple 账户登录。
3. 如果没有付费的 Apple Developer Program 会员资格，账户会显示为 **你的姓名 (Personal Team)**。

“Team”指用于签署 App 的 Apple 开发者账户。你无需加入项目作者的团队。

Personal Team 可以安装开发版 App，但有描述文件到期和部分功能不受支持等限制。请参阅下方的**签名限制与故障排除**。

#### 2. 连接 iPhone 并启用开发者模式

1. 将 iPhone 连接到 Mac。
2. 解锁 iPhone；出现提示时，选择**信任此电脑**。
3. 打开 Xcode 的设备管理界面：新版本为 **Device Hub**，旧版本为 **Window → Devices and Simulators**。
4. 等待 Xcode 识别 iPhone。
5. 在 iPhone 上打开**设置 → 隐私与安全性 → 开发者模式**。
6. 启用开发者模式，并同意重新启动。
7. 重新启动后，解锁 iPhone 并确认启用开发者模式。

如果没有该设置，请先完成与 Xcode 的连接，再检查设置。

#### 3. 连接 Apple Watch 并启用开发者模式

1. 保持 Watch 解锁，并靠近 Mac 和 iPhone。
2. 让 Xcode 发现 Watch。必要时，使用 Device Hub 中添加或配对附近设备的选项。
3. 接受设备上出现的连接或信任提示。
4. 在 Watch 本机上打开**设置 → 隐私与安全性 → 开发者模式**。
5. 启用开发者模式，并同意重新启动。
6. 重新启动后，解锁 Watch，并确认任何启用开发者模式的请求。
7. 必要时，在 Xcode 中重新连接 Watch。

Watch 上的开发者模式设置可能要等 Xcode 尝试连接后才会出现。如果没有该设置，请先建立初始连接，再检查 Watch 的设置。

有关背景信息，请参阅 Apple 的[开发者模式说明](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)。

##### 如果 Device Hub 无法与 Watch 配对

如果配对的 iPhone 处于开机状态，而 Watch 配对或连接失败，可以尝试以下临时解决方法：

1. 先完成上述 iPhone 设置。
2. **暂时关闭 iPhone 电源。**
3. 保持 Watch 开机并解锁，同时启用 Wi-Fi 和蓝牙。
4. 在 **Device Hub/Xcode** 中重新尝试配对或连接 Watch。
5. 接受 Watch 上的连接提示。
6. Watch 连接成功后，重新开启 iPhone。

有用户报告此方法在部分配置中有效。但尚未确认 iPhone 开机是所有 Watch 配对问题的原因，此方法也不一定能解决所有连接问题。

#### 4. 配置签名和唯一的 Bundle Identifier

1. 打开 `HermesEnabler2.xcodeproj`。
2. 在 Xcode 项目导航器中选择蓝色项目图标。
3. 在 **PROJECT** 下选择 **HermesEnabler2**。
4. 打开 **Build Settings**，选择 **All**，并搜索：
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. 将 `com.example.HermesEnabler` 替换为你自己的唯一标识符，例如：
   ```
   com.yourname.HermesEnabler12345
   ```
6. 为 **Debug** 和 **Release** 设置相同的值。
7. 在 **TARGETS** 下选择 **HermesEnabler2**，然后打开 **Signing & Capabilities**。
8. 勾选 **Automatically manage signing**，选择自己的团队。
9. 为 **HermesCompanion** 重复签名设置，选择同一个团队。

保持各 target 现有的 Bundle Identifier 表达式不变：

| Target | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

项目使用这个共享设置来保持 iPhone 和 Watch 标识符的一致性。

如果 Xcode 报告 **Failed Registering Bundle Identifier** 或提示标识符不可用，请选择更独特的 `COMPANION_BUNDLE_IDENTIFIER`。返回 **Signing & Capabilities**；如出现 **Try Again** 按钮，请点击重试。

如果仍有 App Groups 错误，请参阅下方的 **App Groups 错误**。

#### 5. 在 Watch 上构建并运行

1. 选择 **HermesEnabler2** scheme。
2. 选择你的实体 **Apple Watch** 作为运行目标。
3. 点击 **▶ Run**。
4. 等待 Xcode 完成设备准备和 App 安装。
5. HermesEnabler2 在 Watch 上打开后，按照 App 内的说明操作。

**Build Succeeded** 表示编译成功，但安装可能仍在进行。

如果 Xcode 显示 **Installing built products**，请等待安装完成。保持设备靠近并维持连接。

App 运行时，调试会话可能保持活动，这是正常现象。请查看 Watch 屏幕，确认 App 是否已打开。

### 其他方式：使用 Sideloadly 安装 IPA

> **Sideloadly 0.72 的已知问题：** [问题 #43](https://github.com/pookjw/HermesEnabler/issues/43) 报告此版本会在签名过程中移除内嵌的 watchOS App。iPhone App 可以安装，但 HermesEnabler2 不会出现在 Apple Watch 或 iPhone 的 Watch App 中。如果遇到此问题，请使用上方的**使用 Xcode 构建**步骤。
>
> 该报告针对 0.72 版本。此处尚未确认其他 Sideloadly 版本的兼容性。

1. 从 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下载 `HermesEnabler.ipa`。
2. 打开 [Sideloadly](https://sideloadly.io)。
3. 关闭 **Use automatic bundle ID**，选择固定且唯一的 Bundle Identifier。
4. 将 IPA 安装到 iPhone。
5. 在 iPhone 上打开 **Watch → 我的手表 → App**，在**可用 App**下查找 **HermesEnabler2**。
6. 如果出现，将其安装到 Watch，然后打开并按照 App 内的说明操作。
7. 如果没有出现，请使用 Xcode 安装 Watch App。

后续更新请使用相同的 Bundle Identifier 和 Apple 账户，以便保留现有数据和备份。

## 签名限制与故障排除

### Personal Team 到期

免费 Personal Team 的预置描述文件会在七天后到期。到期后，请通过 Xcode 重新构建并安装 App。

更新时请继续使用相同的 Apple 账户和 Bundle Identifier。

### App Groups 错误

本项目包含 **App Groups** 权限。免费 Personal Team 不支持为此功能配置预置描述文件。

如果 Xcode 提示某个 App Group 不可用：

- 检查是否已将 `COMPANION_BUNDLE_IDENTIFIER` 改为唯一的值。
- 如果拥有付费开发者会员资格，请选择对应团队，并确保能够注册相应的 App Group。
- 更改标识符不会解除 Personal Team 的功能限制。

请勿认为移除 App Groups 就是完整的解决方案。问题 #43 报告通过 Xcode 成功安装，但未确认在 watchOS 27.2.1 上不使用 App Groups 时 MobileGestalt 操作是否有效。

仅构建或安装成功，并不能证明 App 的主要功能有效。

### iPhone App 已安装，但缺少 Watch App

如果使用了 Sideloadly 0.72，请在其日志中查找：

```
Watch apps will be stripped from the IPA
```

这表示内嵌的 Watch App 已被移除。仅安装 iPhone App 不会使缺失的 Watch App 可用。请按照上方的 Xcode 安装步骤操作。

## 注意事项

- 更新时使用相同的 Bundle Identifier 和 Apple 账户，以便保留现有 App 数据和备份。
- 删除 App 前，请务必通过 HermesEnabler2 恢复 MobileGestalt 备份。

## 致谢

本项目包含来自 [Gester](https://github.com/sasobhabha/Gester) 的代码。

使用风险由您自行承担。
