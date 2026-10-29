# Capoo v1.0.4 正式版建置與驗收記錄

## 發佈識別

- 版本：1.0.4（versionCode 1000004）
- Android application ID：air.air.capoo
- Android target API：36；最低 API：23
- Android ABI：arm64-v8a、armeabi-v7a、x86、x86_64
- manifest 權限：0
- 簽章憑證 SHA-256：806e00840b245c1f6a430e6ae2aae1d064cde8b078bc2ff224f8f5173a8ba1d8

## 正式產物

| 檔案 | 位元組 | SHA-256 |
| --- | ---: | --- |
| CapooOriginal-v1.0.4-universal.apk | 41,828,516 | F2A96567A1427F3C97D3A9F61002252075A3EC29699552F29A44621570D14700 |
| CapooOriginal-v1.0.4-win-x64.zip | 16,025,680 | 4C7675BD283826FE89E7EF510E8C58E99C04332AA9C8247F35EC0C4A1CA0D02D |

## 建置環境與流程

- AIR SDK 51.4.1.x、JDK 17、Android SDK platform 36.1、Build Tools 36.1.0。
- Node.js 18+ 與鎖定版 swf-toolkit 匯入平台 AS3，從原始 SWF 重建手機與桌面 SWF。
- AIR ADT 以 captive runtime 產生 APK 和 Windows x64 bundle。
- build-release.ps1 使用 aapt 檢查 package、版本、target API、launcher icon 與權限；使用 apksigner 驗證 APK 簽章並與設定指紋比對；最後輸出 SHA256SUMS.txt。
- Windows ZIP 內含 CapooOriginal.exe、圖示資源與 Adobe AIR runtime；執行不依賴外部安裝的 AIR。

## 驗證結果

| 檢查 | 結果 |
| --- | --- |
| APK manifest | 通過；package air.air.capoo，versionName 1.0.4、versionCode 1000004 |
| Android target / ABI | 通過；target API 36，包含 arm64-v8a、armeabi-v7a、x86、x86_64 |
| 權限 | 通過；無 uses-permission |
| APK 簽章 | 通過；本機永久簽章 SHA-256 與 APK signer 一致 |
| Android 圖示 | 通過；描述檔列入六種密度 PNG |
| Windows bundle | 通過；x64 EXE、icons 與 Adobe AIR runtime 均包含 |
| 遊戲功能 | 使用者已回報測試通過；此正式版由已驗收測試版重新以 1.0.4 release label 打包 |

## 下載檔雜湊

源碼 ZIP 與上述產物的最終校驗值會一併發佈在 Release 的 SHA256SUMS.txt。簽章金鑰與 DPAPI 密碼檔位於建置者本機，從未放入公開套件。

## 安裝相容性

新 APK 雖沿用原版 package name，但使用不同簽章。Android 不允許以不同簽章覆蓋既有安裝；安裝前必須卸載舊版，這會清除舊版本機排行榜與資料。未來升級必須用同一份新私鑰重新簽章。
