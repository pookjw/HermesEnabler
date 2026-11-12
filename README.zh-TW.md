# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> 僅支援 watchOS 27.0 至 27.3 beta 1。

## 安裝

### 使用 Xcode 建置

#### 準備工作

你需要：

- 一台 Mac，安裝支援裝置目前 iOS 和 watchOS 版本的 Xcode。
- 已與 iPhone 配對的 Apple Watch。
- 已加入 Xcode 的 Apple 帳號。
- 專案原始碼。透過 **Code → Download ZIP** 下載並解壓縮，或複製此儲存庫。

[Issue #43](https://github.com/pookjw/HermesEnabler/issues/43) 回報了 Sideloadly 0.72 安裝 Watch App 時的問題，因此這裡建議使用 Xcode。下方仍保留 IPA 安裝方式。

#### 1. 將 Apple 帳號加入 Xcode

1. 依 Xcode 版本，開啟 **Xcode → Settings → Accounts** 或 **Apple Accounts**。
2. 點擊 **+**，使用 Apple 帳號登入。
3. 如果沒有付費的 Apple Developer Program 會員資格，帳號會顯示為 **你的姓名 (Personal Team)**。

「Team」是指用來簽署 App 的 Apple 開發者帳號。你不需要加入專案作者的團隊。

Personal Team 可以安裝開發版 App，但有描述檔到期及部分功能不受支援等限制。請參閱下方的**簽署限制與疑難排解**。

#### 2. 連接 iPhone 並啟用開發者模式

1. 將 iPhone 連接至 Mac。
2. 解鎖 iPhone；出現提示時，選擇**信任這部電腦**。
3. 開啟 Xcode 的裝置管理介面：新版本為 **Device Hub**，舊版本為 **Window → Devices and Simulators**。
4. 等待 Xcode 辨識 iPhone。
5. 在 iPhone 上開啟**設定 → 隱私權與安全性 → 開發者模式**。
6. 啟用開發者模式，並同意重新啟動。
7. 重新啟動後，解鎖 iPhone 並確認啟用開發者模式。

如果沒有該設定，請先完成與 Xcode 的連線，再檢查設定。

#### 3. 連接 Apple Watch 並啟用開發者模式

1. 保持 Watch 解鎖，並靠近 Mac 和 iPhone。
2. 讓 Xcode 偵測 Watch。必要時，使用 Device Hub 中加入或配對附近裝置的選項。
3. 接受裝置上出現的連線或信任提示。
4. 在 Watch 本機上開啟**設定 → 隱私權與安全性 → 開發者模式**。
5. 啟用開發者模式，並同意重新啟動。
6. 重新啟動後，解鎖 Watch，並確認任何啟用開發者模式的要求。
7. 必要時，在 Xcode 中重新連接 Watch。

Watch 上的開發者模式設定可能要等 Xcode 嘗試連線後才會出現。如果沒有該設定，請先建立初始連線，再檢查 Watch 的設定。

如需背景資訊，請參閱 Apple 的[開發者模式說明](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)。

##### 如果 Device Hub 無法與 Watch 配對

如果配對的 iPhone 處於開機狀態，而 Watch 配對或連線失敗，可以嘗試以下暫時解決方法：

1. 先完成上述 iPhone 設定。
2. **暫時關閉 iPhone 電源。**
3. 保持 Watch 開機並解鎖，同時啟用 Wi-Fi 和藍牙。
4. 在 **Device Hub/Xcode** 中重新嘗試配對或連接 Watch。
5. 接受 Watch 上的連線提示。
6. Watch 連線成功後，重新開啟 iPhone。

有使用者回報此方法在部分設定下有效。但尚未確認 iPhone 開機是所有 Watch 配對問題的原因，此方法也不一定能解決所有連線問題。

#### 4. 設定簽署與唯一的 Bundle Identifier

1. 開啟 `HermesEnabler2.xcodeproj`。
2. 在 Xcode 專案導覽器中選取藍色專案圖示。
3. 在 **PROJECT** 下選取 **HermesEnabler2**。
4. 開啟 **Build Settings**，選取 **All**，並搜尋：
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. 將 `com.example.HermesEnabler` 替換為你自己的唯一識別碼，例如：
   ```
   com.yourname.HermesEnabler12345
   ```
6. 為 **Debug** 和 **Release** 設定相同的值。
7. 在 **TARGETS** 下選取 **HermesEnabler2**，然後開啟 **Signing & Capabilities**。
8. 勾選 **Automatically manage signing**，選取自己的團隊。
9. 為 **HermesCompanion** 重複簽署設定，選取同一個團隊。

保持各 target 現有的 Bundle Identifier 運算式不變：

| Target | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

專案使用這個共用設定來維持 iPhone 與 Watch 識別碼的一致性。

如果 Xcode 回報 **Failed Registering Bundle Identifier** 或提示識別碼無法使用，請選擇更獨特的 `COMPANION_BUNDLE_IDENTIFIER`。返回 **Signing & Capabilities**；如出現 **Try Again** 按鈕，請點擊重試。

如果仍有 App Groups 錯誤，請參閱下方的 **App Groups 錯誤**。

#### 5. 在 Watch 上建置並執行

1. 選取 **HermesEnabler2** scheme。
2. 選擇你的實體 **Apple Watch** 作為執行目標。
3. 點擊 **▶ Run**。
4. 等待 Xcode 完成裝置準備和 App 安裝。
5. HermesEnabler2 在 Watch 上開啟後，依照 App 內的說明操作。

**Build Succeeded** 表示編譯成功，但安裝可能仍在進行。

如果 Xcode 顯示 **Installing built products**，請等待安裝完成。保持裝置靠近並維持連線。

App 執行時，偵錯工作階段可能持續作用，這是正常現象。請查看 Watch 螢幕，確認 App 是否已開啟。

### 其他方式：使用 Sideloadly 安裝 IPA

> **Sideloadly 0.72 的已知問題：** [Issue #43](https://github.com/pookjw/HermesEnabler/issues/43) 回報此版本會在簽署過程中移除內嵌的 watchOS App。iPhone App 可以安裝，但 HermesEnabler2 不會出現在 Apple Watch 或 iPhone 的 Watch App 中。如果遇到此問題，請使用上方的**使用 Xcode 建置**步驟。
>
> 該回報針對 0.72 版本。此處尚未確認其他 Sideloadly 版本的相容性。

1. 從 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下載 `HermesEnabler.ipa`。
2. 開啟 [Sideloadly](https://sideloadly.io)。
3. 關閉 **Use automatic bundle ID**，選擇固定且唯一的 Bundle Identifier。
4. 將 IPA 安裝至 iPhone。
5. 在 iPhone 上開啟 **Watch → 我的手錶 → App**，在**可用的 App**下尋找 **HermesEnabler2**。
6. 如果出現，將其安裝至 Watch，然後開啟並依照 App 內的說明操作。
7. 如果沒有出現，請使用 Xcode 安裝 Watch App。

後續更新請使用相同的 Bundle Identifier 和 Apple 帳號，以便保留現有資料和備份。

## 簽署限制與疑難排解

### Personal Team 到期

免費 Personal Team 的佈建描述檔會在七天後到期。到期後，請透過 Xcode 重新建置並安裝 App。

更新時請繼續使用相同的 Apple 帳號和 Bundle Identifier。

### App Groups 錯誤

本專案包含 **App Groups** 權限。免費 Personal Team 不支援為此功能設定佈建描述檔。

如果 Xcode 提示某個 App Group 無法使用：

- 檢查是否已將 `COMPANION_BUNDLE_IDENTIFIER` 改為唯一的值。
- 如果擁有付費開發者會員資格，請選取對應團隊，並確保能註冊相應的 App Group。
- 更改識別碼不會解除 Personal Team 的功能限制。

請勿認為移除 App Groups 就是完整的解決方案。Issue #43 回報透過 Xcode 成功安裝，但未確認在 watchOS 27.2.1 上不使用 App Groups 時 MobileGestalt 操作是否有效。

僅建置或安裝成功，並不能證明 App 的主要功能有效。

### iPhone App 已安裝，但缺少 Watch App

如果使用了 Sideloadly 0.72，請在其記錄中尋找：

```
Watch apps will be stripped from the IPA
```

這表示內嵌的 Watch App 已被移除。僅安裝 iPhone App 不會讓缺失的 Watch App 可用。請依照上方的 Xcode 安裝步驟操作。

## 注意事項

- 更新時使用相同的 Bundle Identifier 和 Apple 帳號，以便保留現有 App 資料和備份。
- 刪除 App 前，請務必透過 HermesEnabler2 還原 MobileGestalt 備份。

## 致謝

本專案包含來自 [Gester](https://github.com/sasobhabha/Gester) 的程式碼。

使用風險由您自行承擔。
