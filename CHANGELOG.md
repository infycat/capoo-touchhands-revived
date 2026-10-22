# Changelog

本專案遵循 [Semantic Versioning](https://semver.org/)。

## [1.0.2] — 2026-10-23

### Fixed

- 接管遊戲原生 OK 按鈕的點擊，將暱稱寫入 `role[gsit][0]`，不再誤寫分數欄位。
- 將顯示清單與焦點變更延後到下一幀，避免 Android 軟鍵盤仍開啟時觸發 AIR 崩潰。
- 名稱輸入面板自動上移，避免軟鍵盤遮住 OK 按鈕。
- 加入 `repairScoreSlot()`，在原始 `go_again()` 意外執行時自動修復資料。
- 修復排行榜 `undefined`、成績無法記錄、暱稱無法顯示與持久化等問題。

### Changed

- 發佈流程改為 GitHub Release 附件；APK 不進入 Git 歷史。
- 簽章私鑰與密碼改由 `SIGNING_KEYSTORE`、`SIGNING_PASSWORD` 環境變數提供。
- 端到端測試腳本移除本機絕對路徑，改用 `ADB` 與 `PYTHON` 可覆寫環境變數。

[1.0.2]: https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.2
