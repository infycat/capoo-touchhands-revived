# Capoo 摸摸手復活版 v1.0.3 / Touch Hands Revived v1.0.3

## 繁體中文

這是已斷更 Android 小遊戲《Capoo 摸摸手》的非官方復活版。v1.0.3 是**發佈加固版本**：
在 v1.0.2 修復遊戲機制之後，進一步把開發期設定與多餘權限從正式包中移除。

本次變更：

- **移除 `android:debuggable="true"`** —— 正式包不再是 debuggable，私有目錄無法再被外部工具讀取。
- **移除 `INTERNET` 與 `ACCESS_NETWORK_STATE` 權限** —— 遊戲完全離線，包內附帶的 AdMob ANE
  是死碼（反編譯後確認只有變數型別宣告，位元組碼中從未呼叫），執行時不需要任何網路存取。
  最終 APK 的 `uses-permission` 總數為 **0**，`adt` 亦會輸出
  `Application has not specified its permission requirements` 提示。
- 保留 `uses-sdk`（minSdk 21 / targetSdk 33）不變，`versionCode` 升為 1000003，可直接覆蓋安裝 v1.0.2。
- 建置腳本改為從 `app.xml` 的 `<versionNumber>` 推導產物檔名，版本號與檔名不再會走鍊。
- 端到端測試腳本會依 APK 是否為 debuggable 自動切換驗證模式。

v1.0.2 的主要修復（排行榜 `undefined`、成績無法記錄、暱稱無法顯示與持久化、
OK 按鈕無反應、軟鍵盤開啟時點 OK 可能崩潰）全部保留。

下載：`capoo-touchhands-revived-v1.0.3.apk`

- 平台：Android 8.0+（ARM64）
- 大小：16,721,407 bytes（約 15.95 MiB）
- SHA-256：`6DC218F11090518607BB37A3F6EDEA068D8ED20BEDF9B7B5BAE8A8BAA5D9072B`
- 權限：無
- 網路：完全不需要

## English

An unofficial revival of the discontinued Android game Capoo / Touch Hands.
Version 1.0.3 is the **release-hardening build**: on top of the gameplay fixes
landed in v1.0.2, it strips all development-time settings and every permission
from the shipped APK.

- **`android:debuggable="true"` removed** — the release build is no longer debuggable.
- **`INTERNET` and `ACCESS_NETWORK_STATE` permissions removed** — the game is
  completely offline; the bundled AdMob ANE is dead code (it only appears as a
  variable type declaration and is never called), so no network access is
  required. The final APK declares **0** permissions.
- `uses-sdk` (minSdk 21 / targetSdk 33) unchanged; `versionCode` bumped to
  1000003 so v1.0.3 installs over v1.0.2.
- The build scripts now derive the artifact name from `<versionNumber>` in
  `app.xml`, so the version and the file name can never drift apart.
- The end-to-end test script now detects whether the APK is debuggable and
  switches its verification strategy accordingly.

All v1.0.2 gameplay fixes are preserved: the leaderboard no longer shows
`undefined`, scores are recorded, the in-game name field is editable and
persistent, the original OK button works, and the Android soft-keyboard crash
is gone.

Download: `capoo-touchhands-revived-v1.0.3.apk`

- Platform: Android 8.0+ (ARM64)
- Size: 16,721,407 bytes (about 15.95 MiB)
- SHA-256: `6DC218F11090518607BB37A3F6EDEA068D8ED20BEDF9B7B5BAE8A8BAA5D9072B`
- Permissions: none
- Network: not required

The revival shim and build tooling are MIT-licensed. The original game binary and artwork remain the property of their respective owner(s).
