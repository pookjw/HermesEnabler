# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> 僅支援 watchOS 27.0 至 27.3 beta 1。

## 安裝

### macOS

在 macOS 上，你可以用 Sideloadly 安裝預先建置的 IPA，也可以直接用 Xcode 建置 App。兩種方式都要求 iPhone 已與目標 Apple Watch 配對，且手錶執行受支援的 watchOS 版本。

#### 安裝 IPA

> **Sideloadly 0.72 已知問題：** [問題 #43](https://github.com/pookjw/HermesEnabler/issues/43) 回報此版本可能在簽署時移除 IPA 內嵌的 Watch App。如果 iPhone App 已安裝，但 Watch 上沒有 HermesEnabler2，請改用 Xcode。此回報針對 0.72 版本，其他版本的相容性尚未確認。

1. 從 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下載 IPA。
2. 在 Mac 上安裝 [Sideloadly](https://sideloadly.io)，用傳輸線連接 iPhone，並在 Sideloadly 中選擇該裝置。
3. 將 IPA 拖入 Sideloadly 並輸入 Apple ID。關閉 **Use automatic bundle ID**，指定固定的 Bundle Identifier，然後開始簽署。
4. 在 iPhone 上打開 **設定 → 一般 → VPN 與裝置管理**，信任你的開發者憑證。
5. 在 iPhone 上打開 **設定 → 隱私權與安全性 → 開發者模式**，開啟、重新啟動並確認。
6. 在 iPhone 的 **Watch App → 我的手錶 → App** 中，將 **HermesEnabler2** 安裝到手錶。
7. 在 Apple Watch 上打開 **設定 → 隱私權與安全性 → 開發者模式**，開啟、重新啟動並確認。如果沒有顯示此選項，請先安裝手錶 App，然後再次查看。
8. 在 Apple Watch 上打開 **HermesEnabler2**，並依照 App 中的步驟操作。

#### 使用 Xcode 建置

你需要一台安裝了相容裝置 iOS 和 watchOS 版本的 Xcode 的 Mac，以及已與 iPhone 配對的 Apple Watch。

1. 透過 **Code → Download ZIP** 下載並解壓縮原始碼，或複製此儲存庫。在 Xcode 中開啟 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)。
2. 在 **Xcode → Settings → Accounts**（或 **Apple Accounts**）中加入 Apple 帳號。在 **TARGETS** 下，分別開啟 **HermesEnabler2** 和 **HermesCompanion** 的 **Signing & Capabilities**，啟用 **Automatically manage signing**，並為兩者選取自己的同一個團隊。
3. 選取藍色專案圖示，再開啟 **PROJECT → HermesEnabler2 → Build Settings → All**。搜尋 `COMPANION_BUNDLE_IDENTIFIER`，將 `com.example.HermesEnabler` 替換為自己的唯一識別碼，為 **Debug** 和 **Release** 設定相同的值。保持各 target 現有的 Bundle Identifier 運算式不變。
4. 連接並解鎖 iPhone，接受信任提示，讓 Xcode 透過 **Device Hub** 或 **Window → Devices and Simulators** 偵測 Watch。在兩台裝置上啟用**設定 → 隱私權與安全性 → 開發者模式**，重新啟動並確認。如果沒有該設定，請先讓 Xcode 嘗試連線，再檢查設定。
5. 選取 **HermesEnabler2** scheme 和實體 **Apple Watch** 作為執行目標，然後點擊 **▶ Run**。等待安裝完成，在 Watch 上開啟 **HermesEnabler2** 並依照 App 中的步驟操作。**Build Succeeded** 表示編譯完成，安裝可能仍在進行。

> 如果 Device Hub 無法連接 Watch，有使用者回報暫時關閉已配對 iPhone 的電源後重試會有所幫助。保持 Watch 解鎖，並啟用 Wi-Fi 和藍牙；連線成功後再開啟 iPhone。此方法不一定適用於所有設定。
>
> 有關 Personal Team 到期和 App Groups 簽署限制，請參閱下方的**注意事項**。後續更新請繼續使用相同的 Apple 帳號和 Bundle Identifier。

### Windows

Windows 上使用 [WatchBridge](https://github.com/AdminZachary/iloader-for-windows)。它是一個社群工具，可準備開發者模式，並安裝同時包含 iPhone 宿主 App 和 Watch App 的 IPA。它與 Apple 或本專案沒有官方關聯。

1. 安裝 [iTunes](https://www.apple.com/itunes/) 或 Microsoft Store 中的 **Apple Devices** App，以取得 **Apple Mobile Device Service**。WatchBridge 的 USB 與 Wi-Fi 通訊都依賴此服務。Windows 11 已內建 WebView2。
2. 確認 iPhone 已與目標 Apple Watch 配對。WatchBridge 一次僅支援一台已配對手錶；若配對多台，準備步驟會停止，而不會猜測目標。
3. 從 [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest) 下載 `watchbridge-windows.zip`，解壓縮並執行 `WatchBridge.exe`。此程式未簽署，首次執行時 Windows SmartScreen 可能會提示。
4. 從 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下載 IPA。請使用同時包含 iPhone 宿主與 `Watch/*.app` 的原始 IPA；不支援僅含 Watch 的套件。
5. 透過 USB 連接已配對的 iPhone，並在 WatchBridge 中選擇該裝置。
6. 配對手錶，並在手錶上確認信任提示。要求**開發者模式**開關後，在手錶上打開 **設定 → 隱私權與安全性 → 開發者模式**，開啟、重新啟動並確認。回到 WatchBridge 並點擊 **Check again**。WatchBridge 不會替你開啟開發者模式或重新啟動手錶。
7. 登入 Apple ID，選擇 HermesEnabler2 的 IPA，然後開始簽署與安裝。WatchBridge 會先安裝 iPhone 宿主 App，再安裝手錶 App。
8. 在 Apple Watch 上打開 **HermesEnabler2**，並依照 App 中的步驟操作。

> 開發者模式準備需要 USB 連接。透過 USB 配對一次後，即可使用 Wi-Fi 安裝與續簽。

## 注意事項

- 在 Sideloadly 中關閉 **Use automatic bundle ID**，並使用固定的 Bundle Identifier。每次更新時都使用相同的 Bundle Identifier 和 Apple ID，以便保留現有的 App 資料和備份。
- 免費 Apple Personal Team 的佈建描述檔會在 7 天後到期。到期後，請使用相同的 Apple ID 和 Bundle Identifier 重新建置並安裝 App。
- 本專案使用 **App Groups** 權限，免費 Personal Team 無法為其佈建簽署。可能需要付費開發者團隊；更改 Bundle Identifier 並不能消除此限制。不要假設移除此權限就能完全解決問題，因為尚未確認移除後 App 的主要功能是否正常。
- 如果 iPhone App 已安裝但 Watch App 沒有出現，請在 Sideloadly 紀錄中尋找 `Watch apps will be stripped from the IPA`。這表示內嵌的 Watch App 已遭移除；請使用 Xcode 安裝 Watch App。
- 刪除 App 前，請務必透過 HermesEnabler2 App 還原 MobileGestalt 備份。

## 致謝

本專案包含來自 [Gester](https://github.com/sasobhabha/Gester) 的程式碼。

使用風險由您自行承擔。
