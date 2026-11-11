# HermesEnabler 2
[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler 是在 Apple Watch 上修改 MobileGestalt 回報的裝置屬性與功能旗標的 App。iPhone 伴隨 App 用於安裝手錶 App。功能旗標無法增加硬體或取得不符合資格的服務。

> 僅支援 watchOS 27.0 至 27.3 beta 1。

![Apple Watch](image.png)

## 使用 Xcode 建置與安裝

1. 安裝含 iOS 與 watchOS SDK 的 Xcode。連接已與目標 Apple Watch 配對的 iPhone，信任裝置，並依 Xcode 提示開啟開發者模式。
2. 複製本儲存庫，並在 Xcode 中打開 `HermesEnabler2.xcodeproj`。
3. 在 **Signing & Capabilities** 中，為 **HermesCompanion** 和 **HermesEnabler2** 選擇自己的 Apple Development 團隊。將 `COMPANION_BUNDLE_IDENTIFIER` 設為自己控制且不重複的 iPhone Bundle ID；手錶 App 的 ID 會加上 `.watchkitapp`。
4. 為目標與佈建描述檔設定相符的 App Group。手錶 entitlement 使用 `group.$(COMPANION_BUNDLE_IDENTIFIER)`；缺少 App Group 可能導致 MobileGestalt 存取或備份失敗。
5. 選擇 **HermesCompanion** Scheme 和已配對的 iPhone，執行 **Product → Run**。如未自動安裝手錶 App，請在 iPhone 的 Watch App 中從 **我的手錶 → App／可用 App** 安裝。
6. 在 Apple Watch 上打開 HermesEnabler，先建立初始 MobileGestalt 備份；測試多個選項前，請保留已知可用的備份。

只檢查編譯而不簽署，可執行：

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh` 產生內含手錶 App 的**未簽署** iPhone IPA。安裝前仍須使用適當的憑證與佈建描述檔簽署兩個 App。

## 安裝發行版 IPA

從 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下載 IPA，依自己的簽署設定安裝；如有需要，再從 iPhone 的 Watch App 安裝手錶 App。

## 功能一覽

| 功能 | 選單 | 作用與限制 |
|---|---|---|
| Hermès | 錶面 | 切換回報的「Hermès」能力。 |
| Ultra 錶面 | 錶面 | 切換 Ultra 錶面能力；啟用後無法使用 Hermès Faubourg Party 錶面。重新啟動手錶。 |
| 永遠顯示 | 顯示與控制 | 切換回報的「永遠顯示」能力。 |
| 永遠顯示 1 Hz | 顯示與控制 | 切換回報的「永遠顯示 1 Hz」能力。 |
| 永遠顯示色彩鮮明度 | 顯示與控制 | 切換回報的「永遠顯示色彩鮮明度」能力。 |
| 定期更新環境光 | 顯示與控制 | 切換回報的「定期更新環境光」能力。 |
| 螢幕解析度 | 顯示與控制 | 選擇回報尺寸或還原原尺寸；不會改變實際像素，可能裁切介面。重新啟動手錶。 |
| 動作按鈕 | 顯示與控制 | 切換回報的「動作按鈕」能力。 |
| 互點兩下 | 顯示與控制 | 切換回報的「互點兩下」能力。 |
| 螢幕鍵盤 | 顯示與控制 | 切換回報的「螢幕鍵盤」能力。 |
| 抬腕喚醒 | 顯示與控制 | 切換回報的「抬腕喚醒」能力。 |
| 抬起手腕說話 | 顯示與控制 | 切換回報的「抬起手腕說話」能力。 |
| Siri 聆聽功能 | 顯示與控制 | 切換回報的「Siri 聆聽功能」能力。 |
| 水深感測器 | 感測器與體能訓練 | 切換回報的「水深感測器」能力。 |
| 絕對高度計 | 感測器與體能訓練 | 切換回報的「絕對高度計」能力。 |
| 常顯指南針 | 感測器與體能訓練 | 切換回報的「常顯指南針」能力。 |
| 指南針定向 | 感測器與體能訓練 | 切換回報的「指南針定向」能力。 |
| 連續心率監測 | 感測器與體能訓練 | 切換回報的「連續心率監測」能力。 |
| 噪音暴露 | 感測器與體能訓練 | 切換回報的「噪音暴露」能力。 |
| 電池資訊 | 感測器與體能訓練 | 切換回報的「電池資訊」能力。 |
| 游泳體能訓練 | 感測器與體能訓練 | 切換回報的「游泳體能訓練」能力。 |
| 地區代碼 | Siri & 智能 | 只修改 RegionCode，不修改銷售地區後綴。 |
| 銷售地區 | Siri & 智能 | 只修改銷售地區後綴；出廠資訊工具可能顯示不符。 |
| Apple Intelligence / Siri AI | Siri & 智能 | 切換能力；Siri AI 仍需 watchOS 27、支援的手錶與配對的 Apple Intelligence iPhone。 |
| 裝置端 Siri | Siri & 智能 | 切換回報的「裝置端 Siri」能力。 |
| 音訊智能 | Siri & 智能 | 切換音訊智能能力；App 指出需要 Series 12／Ultra 4 硬體。 |
| 初始備份 | MG 備份 | 建立受保護、不可在 App 中覆寫的初始備份。 |
| 手動備份 | MG 備份 | 手動備份目前的 MobileGestalt。 |
| 自動備份 | MG 備份 | MG 寫入或還原前自動建立備份。 |
| 還原 MG | MG 備份 | 還原所選備份；先備份目前 MG，之後重新啟動手錶。 |
| 重新啟動 Carousel | 工具 | 重新啟動手錶介面程序以載入相關變更。 |

能力旗標無法補足缺少的顯示器、感測器或音訊硬體，也無法略過系統服務限制。地區與解析度頁面提供預設值；寫入失敗時，App 會顯示狀態或錯誤。

## 致謝

本專案包含來自 [Gester](https://github.com/sasobhabha/Gester) 的程式碼。使用風險由您自行承擔。
