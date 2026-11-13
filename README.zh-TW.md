# HermesEnabler 2

[English](README.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> 僅支援 watchOS 27.0 至 27.3 beta 1。

## 安裝

### macOS

在 macOS 上，你可以用 Sideloadly 安裝預先建置的 IPA，也可以直接用 Xcode 建置 App。兩種方式都要求 iPhone 已與目標 Apple Watch 配對，且手錶執行受支援的 watchOS 版本。

#### 安裝 IPA

1. 從 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下載 IPA。
2. 在 Mac 上安裝 [Sideloadly](https://sideloadly.io)，用傳輸線連接 iPhone，並在 Sideloadly 中選擇該裝置。
3. 將 IPA 拖入 Sideloadly 並輸入 Apple ID。關閉 **Use automatic bundle ID**，指定固定的 Bundle Identifier，然後開始簽署。
4. 在 iPhone 上打開 **設定 → 一般 → VPN 與裝置管理**，信任你的開發者憑證。
5. 在 iPhone 上打開 **設定 → 隱私權與安全性 → 開發者模式**，開啟、重新啟動並確認。
6. 在 iPhone 的 **Watch App → 我的手錶 → App** 中，將 **HermesEnabler2** 安裝到手錶。
7. 在 Apple Watch 上打開 **設定 → 隱私權與安全性 → 開發者模式**，開啟、重新啟動並確認。如果沒有顯示此選項，請先安裝手錶 App，然後再次查看。
8. 在 Apple Watch 上打開 **HermesEnabler2**，並依照 App 中的步驟操作。

#### 使用 Xcode 建置

1. 在 Xcode 中打開 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)。
2. 選擇 Apple Watch 作為執行目標，然後點擊 **Run**。
3. 在 Apple Watch 上打開 **HermesEnabler2**，並依照 App 中的步驟操作。

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
- 由於 **App Groups** 權限，必須使用付費的 Apple Developer 帳號。
- 如果 iPhone App 已安裝但 Watch App 沒有出現，請在 Sideloadly 紀錄中尋找 `Watch apps will be stripped from the IPA`。這表示內嵌的 Watch App 已遭移除；請使用 Xcode 安裝 Watch App。
- 刪除 App 前，請務必透過 HermesEnabler2 App 還原 MobileGestalt 備份。

## 致謝

本專案包含來自 [Gester](https://github.com/sasobhabha/Gester) 的程式碼。

使用風險由您自行承擔。
