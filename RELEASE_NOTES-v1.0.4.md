# Capoo 摸摸手 v1.0.4 — 原版玩法保存正式版

這是以完整原版 ActionScript 3 遊戲邏輯重建的 Android 與 Windows 版本。

## 下載

- Android APK：CapooOriginal-v1.0.4-universal.apk
- Windows x64 portable bundle：CapooOriginal-v1.0.4-win-x64.zip
- 完整源碼：CapooOriginalSource-v1.0.4.zip
- SHA-256：SHA256SUMS.txt

## 本版內容

- 保留原版時間軸、六區拍手玩法、計分、連擊、計時、結算、經驗值與本機前五名 SQLite 排行榜。
- Android 用 TouchEvent；Windows 用 MouseEvent 轉接到同一組原版玩法 handler。
- Android 包名 air.air.capoo、versionCode 1000004、target API 36，包含四種 ABI，manifest 權限數 0。
- APK 使用 captive runtime；Windows ZIP 包含 Adobe AIR runtime，無需另外安裝 AIR。
- 使用 Capoo launcher icon，正式版 build label 為 1.0.4。

## 安裝提示

原版簽章私鑰無法解鎖。此版使用新的長期簽章；安裝前要先卸載舊版，卸載會清除舊版本機排行榜。日後更新必須持續使用同一把私鑰。

此版本為非官方保存與相容性重建，不代表 Carter Island Studio 官方發佈。原作名稱、美術、音效、SWF 和 AS3 的權利仍屬原權利人。
