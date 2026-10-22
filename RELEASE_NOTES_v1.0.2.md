# Capoo 摸摸手復活版 v1.0.2 / Touch Hands Revived v1.0.2

## 繁體中文

這是已斷更 Android 小遊戲《Capoo 摸摸手》的非官方復活版。v1.0.2 修復排行榜 `undefined`、成績無法記錄、名稱輸入框不可用、OK 無反應，以及軟鍵盤開啟時點 OK 可能崩潰等問題。

主要修復：

- 正確將暱稱寫入名稱欄位，而不是分數欄位。
- 透明熱區接管遊戲原生 OK 按鈕，保留原本美術。
- 所有關閉動作延後到下一幀，避免 AIR 軟鍵盤時序崩潰。
- 名稱面板自動上移，避免被軟鍵盤遮住。
- 加入分數欄自我修復與未捕捉錯誤攔截。
- 真機實測點擊 OK 到上榜為 28 ms，程序存活且無 FATAL。

下載：`capoo-touchhands-revived-v1.0.2.apk`

- 平台：Android 8.0+（ARM64）
- 大小：16,721,151 bytes（約 15.95 MiB）
- SHA-256：`806A17612B2D97359A69A9EE961652ADD5AF722A54EF27FFA9C769B15DC97D44`

## English

An unofficial revival of the discontinued Android game Capoo / Touch Hands. Version 1.0.2 restores the leaderboard and score persistence, repairs the name-entry field and OK button, avoids the Android soft-keyboard crash, and adds defensive recovery for corrupted score slots.

Download: `capoo-touchhands-revived-v1.0.2.apk`

- Platform: Android 8.0+ (ARM64)
- Size: 16,721,151 bytes (about 15.95 MiB)
- SHA-256: `806A17612B2D97359A69A9EE961652ADD5AF722A54EF27FFA9C769B15DC97D44`

The revival shim and build tooling are MIT-licensed. The original game binary and artwork remain the property of their respective owner(s).
