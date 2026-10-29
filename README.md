# Capoo 摸摸手（Capoo touch）原版玩法保存版 v1.0.4

**繁體中文** · [简体中文](README.zh-CN.md) · [English](README.en.md)

## 直接下載

**[下載 Android APK](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-universal.apk)** · **[下載 Windows x64 ZIP](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-win-x64.zip)** · [完整源碼 ZIP](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginalSource-v1.0.4.zip)

所有正式成品均附在 GitHub Release，請優先使用下列連結：

| 平台 | 下載資源 | 說明 |
| --- | --- | --- |
| Android | [CapooOriginal-v1.0.4-universal.apk](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-universal.apk) | 通用 APK，含 AIR runtime |
| Windows x64 | [CapooOriginal-v1.0.4-win-x64.zip](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-win-x64.zip) | 解壓後執行 CapooOriginal.exe；ZIP 內含 AIR runtime |
| 完整源碼 | [CapooOriginalSource-v1.0.4.zip](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginalSource-v1.0.4.zip) | 原始 AS3、平台適配、圖示、建置腳本與文件 |
| 校驗檔 | [SHA256SUMS.txt](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/SHA256SUMS.txt) | 驗證 APK、Windows 套件與源碼 ZIP |

Release 頁面：[v1.0.4 全部資源與發佈說明](https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.4)

> 這是社群保存與相容性重建版本，非 Carter Island Studio 官方新版。此版以完整原版 ActionScript 3 遊戲邏輯製作，提供 Android 手機版與 Windows 桌面版。

## 為什麼重建

《Capoo touch／Capoo 摸摸手》是 Carter Island Studio 推出的舊版 Android 小遊戲。歷史應用目錄記錄的官方包名為 <code>air.capoo</code>、最終可查版本為 1.0.1，並記錄 2018 年下架。這些是第三方歷史目錄資料，並非工作室的停運公告：[AppBrain 版本記錄](https://www.appbrain.com/app/capoo-touch/air.capoo)、[APKCombo 版本記錄](https://apkcombo.com/capoo-touch/air.capoo/)。

原版建立於舊版 Adobe AIR 與當年的 Android 相容環境；隨 Android 系統、處理器架構與 runtime 政策演進，部分新裝置會遇到無法安裝或啟動的情況。本專案重新整理原始 AS3 與 SWF 資源，使用 AIR captive runtime 打包，讓 runtime 隨 APK 或 Windows 套件一起提供。Android 發佈包設定 target API 36，包含 ARM64、ARMv7、x86 與 x86_64。

## v1.0.3 與 v1.0.4 的關係

v1.0.3 是早期復活版：保留原遊戲 SWF，透過小型 AS3 引導層修補排行榜與結算輸入流程。它的原始碼、README、標籤及 APK Release 均保留，請見 [v1.0.3 原始文件](https://github.com/infycat/capoo-touchhands-revived/blob/v1.0.3/README.md) 與 [v1.0.3 APK 發佈頁](https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.3)。

v1.0.4 是獨立的新一代版本：以完整原版 AS3 遊戲程式碼重建時間軸與玩法流程，不以 v1.0.3 引導層代替遊戲本體。手機版使用原本六區 TouchEvent；Windows 版只加入滑鼠事件轉接，最後仍呼叫相同六個玩法處理器。動畫、關卡節奏、計分、連擊、計時、結算與本機排行榜均保留。

## 遊戲與程式結構

~~~mermaid
flowchart LR
  A[原版 AS3 17 個類別] --> B[swf-toolkit 重建]
  C[原版 capoo.swf 與美術] --> B
  B --> D[Android SWF]
  B --> E[Windows SWF]
  D --> F[AIR captive runtime]
  F --> G[Universal APK]
  E --> H[AIR Windows bundle]
  H --> I[CapooOriginal.exe + runtime]
  J[assets/icons] --> G
  J --> H
~~~

~~~mermaid
mindmap
  root((Capoo v1.0.4))
    復活目標
      舊 AIR 遊戲可在新 Android 安裝
      保留原版玩法
      提供 Windows 滑鼠版
    遊戲核心
      主選單與排行榜
      六個拍手觸控區
      計時與正確判斷
      分數與連擊
      結算與名稱輸入
      SQLite 本機前五名
    平台包裝
      Android 觸控
      Windows 滑鼠轉接
      隨包附帶 AIR runtime
      零 Android 權限
    發佈物
      APK
      Windows ZIP
      完整源碼 ZIP
      SHA-256 校驗
~~~

## 玩法資料分析

以下數值直接依發布用 AS3 流程整理，描述遊戲既有機制，並非遙測或玩家行為統計。

| 資料項目 | 原版程式邏輯 |
| --- | --- |
| 輸入區 | 左右各三區，共六個拍手區；手機觸控與 Windows 滑鼠共用相同玩法函式 |
| 回合計時 | 起始 100 個 100 ms 計時刻度；有效命中依進度補回 1–2 個刻度 |
| 連擊階段 | 命中數達 20、50 時切換連擊階段；內部加分值依階段設為 51、203、302 |
| 背景進度 | 命中數達 50、100、200 會推進對應背景狀態 |
| 結算與排名 | 排行榜保存前五名；SQLite 的 <code>gamed</code> 表包含五組名字／分數欄位，資料保存在本機 |
| 顯示分數 | 結算顯示命中數；內部 score 另供經驗值與進度計算 |

完整處理流程、原始類別對照與測試證據見源碼 ZIP 內的 <code>docs/ARCHITECTURE.md</code> 與 <code>TEST-REPORT.md</code>。

## 安裝與身分資訊

- Android application ID：<code>air.air.capoo</code>；descriptor id 為 <code>air.capoo</code>。
- 版本：<code>1.0.4</code>，versionCode <code>1000004</code>；最低 Android API 23、target API 36。
- APK 包含 <code>arm64-v8a</code>、<code>armeabi-v7a</code>、<code>x86</code>、<code>x86_64</code> 四種 ABI。
- Android manifest 未要求任何權限；遊戲流程離線運行。
- APK 使用 captive runtime；Windows ZIP 內含 AIR runtime。安裝及執行不需要另裝 AIR。
- Windows 請先完整解壓 ZIP，再從解壓資料夾執行 <code>CapooOriginal.exe</code>，不要單獨移出 EXE。

### Android 簽章注意事項

原版簽章私鑰密碼無法取得，因此 v1.0.4 使用新建立的長期簽章。證書 SHA-256：

~~~text
806e00840b245c1f6a430e6ae2aae1d064cde8b078bc2ff224f8f5173a8ba1d8
~~~

這個簽章與原版及 v1.0.3 不同，Android 會拒絕直接覆蓋安裝。安裝前必須先卸載舊版；Android 卸載會清除該 App 的本機排行榜與資料。未來升級必須持續使用這把新私鑰。發佈 ZIP 不含私鑰或密碼；請安全備份自己的私鑰。

## 正式包驗證摘要

| 項目 | 結果 |
| --- | --- |
| Android APK | 41,828,516 bytes；package <code>air.air.capoo</code>；versionName <code>1.0.4</code>、versionCode <code>1000004</code> |
| Android 平台 | target API 36；四種 ABI；launcher icon 已打包；權限數 0 |
| APK 簽章 | apksigner 驗證通過；簽章指紋與本版長期憑證一致 |
| Windows | 16,025,680 bytes；含 x64 EXE、Capoo icon 與 AIR runtime |
| 功能驗收 | 使用者確認測試通過；本次正式版由測試版設定轉為 release label 並重新封裝 |

完整檔案 SHA-256 以 Release 中的 <code>SHA256SUMS.txt</code> 為準；建置與驗收細節見 [TEST-REPORT.md](TEST-REPORT.md)，版本摘要見 [RELEASE_NOTES-v1.0.4.md](RELEASE_NOTES-v1.0.4.md)。

## 取得源碼與重新建置

源碼 ZIP 內包含原始 AS3、Android/Windows 平台副本、圖示、SWF 重建腳本、AIR application descriptors、建置腳本和本文件。建置需要 Node.js 18+、鎖定版 swf-toolkit、AIR SDK 51.4.1.x、JDK 17 與 Android SDK platform 36。

~~~powershell
npm ci --ignore-scripts
& '.\build\create-signing-key.ps1'
& '.\build\build-release.ps1' -AirSdk 'C:\path\to\AIRSDK_51.4.1' -Jdk 'C:\path\to\jdk-17' -AndroidSdk 'C:\path\to\Android\Sdk'
~~~

新建立的簽章不能覆蓋既有安裝。若需要維持本版升級相容性，必須保留並使用同一份私鑰；私鑰與 DPAPI 密碼檔都不在公開源碼 ZIP 中。

## 原始碼範圍與權利

原始輸入檔 SHA-256：<code>c7cfac6dbf742d6af3222f48681b6edd091f6ec55709ef8be12cc4f3a803cab7</code>。本版不打包廣告 ANE、不請求網路權限，遊戲不需要網路連線。

原作名稱、美術、音效、SWF 及其原始 AS3 仍屬原權利人；本專案是非官方保存與相容性重建，不主張擁有原作。倉庫的 MIT 聲明僅依其原文適用於先前復活引導層及建置工具，不延伸授權原作素材。詳細說明見 <code>COPYRIGHT.md</code>。

## 參考資料

- [AppBrain：Capoo touch 歷史版本與上架記錄](https://www.appbrain.com/app/capoo-touch/air.capoo)
- [APKCombo：Capoo touch 版本資訊](https://apkcombo.com/capoo-touch/air.capoo/)
- [AIR SDK：Android descriptor elements](https://airsdk.dev/docs/building/application-descriptor-files/elements/android)
- [AIR SDK：Windows 安裝與建置需求](https://airsdk.dev/docs/basics/install/windows)
