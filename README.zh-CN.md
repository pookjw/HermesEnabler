# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler 是一款在 Apple Watch 上修改 MobileGestalt 报告的设备属性和功能标志的 App。iPhone 伴侣 App 用于安装和引导打开手表 App。功能标志不能增加硬件，也不能绕过服务资格限制。

> 仅支持 watchOS 27.0 至 27.3 beta 1。

![显示 Hermès 表盘的 Apple Watch](image.png)

## 使用 Xcode 编译和安装

1. 安装包含 iOS、watchOS SDK 的 Xcode。连接已与目标 Apple Watch 配对的 iPhone，信任设备，并按 Xcode 提示启用开发者模式。
2. 克隆本仓库，在 Xcode 中打开 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)。
3. 在 **Signing & Capabilities（签名与功能）** 中，为 **HermesCompanion** 和 **HermesEnabler2** 选择自己的 Apple Development 团队。将 `COMPANION_BUNDLE_IDENTIFIER` 改为自己控制的唯一 iPhone Bundle ID；手表 App 的 ID 会在其后加上 `.watchkitapp`。
4. 为目标和描述文件配置匹配的 App Group。手表目标的 entitlements 使用 `group.$(COMPANION_BUNDLE_IDENTIFIER)`；缺少 App Group 可能导致 MobileGestalt 访问或备份创建失败。
5. 选择 **HermesCompanion** Scheme 和已配对的 iPhone 作为运行目标，点击 **Product → Run（产品 → 运行）**。如未自动安装手表 App，在 iPhone 的 Watch App 中通过 **我的手表 → App / 可用 App** 安装 HermesEnabler。
6. 在 Apple Watch 上打开 HermesEnabler，先创建初始 MobileGestalt 备份。尝试多个选项前，请保留一份确认可用的备份。

仅检查编译而不签名，可在仓库目录运行：

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh` 会生成内嵌手表 App 的**未签名** iPhone IPA。安装前仍需使用合适的证书和描述文件对两个 App 签名。

## 安装发行版 IPA

从 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下载 IPA，按你的签名配置选择安装方式。如有需要，再从 iPhone 的 Watch App 安装手表 App。

## 功能一览

下表对应当前 SwiftUI 菜单。功能开关不能补上缺失的显示、传感器、音频硬件，也不能绕过系统或服务限制。

| 功能 | 菜单 | 作用与限制 |
|---|---|---|
| Hermès | 表盘 | 切换 Hermès 表盘能力；修改后重新启动 Carousel。 |
| Ultra 表盘 | 表盘 | 切换 Ultra 表盘能力；启用后无法使用 Hermès Faubourg Party 表盘。修改后重新启动手表。 |
| 全天候显示 | 显示和控制 | 修改报告的全天候显示能力。 |
| 全天候显示 1 Hz | 显示和控制 | 修改 1 Hz 能力；表盘本身须支持在全天候显示时显示秒数。 |
| 全天候显示色彩鲜艳度 | 显示和控制 | 修改常显状态的色彩鲜艳度能力。 |
| 定期更新环境光 | 显示和控制 | 修改环境光定期更新能力。 |
| 屏幕分辨率 | 显示和控制 | 选择报告尺寸预设或恢复原尺寸；不改变物理像素，可能裁切界面。修改后重新启动手表。 |
| 操作按钮 | 显示和控制 | 修改报告的操作按钮能力；仍需对应硬件。 |
| 互点两下 | 显示和控制 | 修改报告的互点两下能力。 |
| 屏幕键盘 | 显示和控制 | 修改键盘能力。 |
| 抬腕时唤醒 | 显示和控制 | 修改抬腕唤醒能力。 |
| 抬腕对话 | 显示和控制 | 修改 Siri 抬腕对话能力。 |
| Siri 聆听能力 | 显示和控制 | 修改聆听能力；仍受 Siri 设置和音频硬件限制。 |
| 深度计 | 传感器和锻炼 | 修改深度传感器能力；仍需传感器硬件。 |
| 绝对高度计 | 传感器和锻炼 | 修改高度计能力。 |
| 常显指南针 | 传感器和锻炼 | 修改指南针能力。 |
| 指南针定向 | 传感器和锻炼 | 修改指南针定向能力。 |
| 连续心率监测 | 传感器和锻炼 | 修改连续心率能力；仍受传感器和“健康”设置限制。 |
| 噪声暴露 | 传感器和锻炼 | 修改噪声暴露能力。 |
| 电池信息 | 传感器和锻炼 | 修改电池信息能力。 |
| 游泳体能训练 | 传感器和锻炼 | 修改游泳体能训练能力。 |
| 地区代码 | Siri 与智能 | 仅修改 `RegionCode`，不修改销售地区后缀。 |
| 销售区域 | Siri 与智能 | 仅修改销售地区后缀；出厂信息工具可能显示不匹配。 |
| Apple 智能 / Siri AI | Siri 与智能 | 修改报告的能力；App 说明 Siri AI 需要 watchOS 27、受支持的手表及已配对的 Apple 智能 iPhone。 |
| 设备端 Siri | Siri 与智能 | 修改设备端 Siri 能力。 |
| 音频智能 | Siri 与智能 | 修改音频智能能力；App 说明其需要 Series 12 / Ultra 4 硬件。 |
| 初始备份 | MG 备份 | 创建受保护的初始备份；App 内不可覆盖。 |
| 手动备份 | MG 备份 | 手动备份当前 MobileGestalt。 |
| 自动备份 | MG 备份 | 每次写入或恢复 MG 前自动备份。 |
| 恢复 MG | MG 备份 | 先备份当前 MG，再恢复所选备份；可删除非初始备份。恢复后重新启动手表。 |
| 重启 Carousel | 工具 | 重启手表界面进程，重新载入相关变更。 |

地区和屏幕分辨率页面提供预设值。写入失败或无法验证时，App 会显示状态或错误消息。

## 致谢

本项目包含来自 [Gester](https://github.com/sasobhabha/Gester) 的代码。使用风险由您自行承担。
