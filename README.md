# Capoo 摸摸手 · 復活版（Touch Hands — Revived）

[![下載最新版 APK](https://img.shields.io/badge/下載最新版_APK-v1.0.3-2ea44f?style=for-the-badge&logo=android)](https://github.com/infycat/capoo-touchhands-revived/releases/latest/download/capoo-touchhands-revived-v1.0.3.apk)

**[直接下載 APK](https://github.com/infycat/capoo-touchhands-revived/releases/latest/download/capoo-touchhands-revived-v1.0.3.apk)** · [查看 v1.0.3 發佈說明](https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.3) · [瀏覽全部版本](https://github.com/infycat/capoo-touchhands-revived/releases)

> Android ARM64 · 16.7 MB · SHA-256 `6DC218F11090518607BB37A3F6EDEA068D8ED20BEDF9B7B5BAE8A8BAA5D9072B`
>
> **純離線 · 零權限 · 非 debuggable**

> **English TL;DR** — Capoo (摸摸手 / Touch Hands) is a small Android game built
> with Adobe AIR + ActionScript 3 (Flash) whose original author stopped
> maintaining it. On modern Android the leaderboard showed `undefined`, scores
> were never recorded, and the name-entry box was broken. This repo **revives**
> it: a tiny boot shim (`src/Boot.as`) restores the missing leaderboard/score
> logic and the in-game name box, and we re-package an installable APK so
> anyone can play again. Code is MIT; the original game binary (`capoo.swf`)
> belongs to its original author (see [License](./LICENSE)).

---

## 一、这是什么

**Capoo（摸摸手 / Touch Hands）** 是一款用 **Adobe AIR + ActionScript 3（Flash）**
制作的安卓小游戏。原作者早已**断更（停止维护）**，而随着安卓系统与新版 AIR
运行时的变化，原版 APK 装到现在的手机上会出现一组致命问题：主菜单木牌分数、
游戏结束后的排行榜（RANK）全部显示 `undefined`，分数无法记录，名字输入框
要么干脆不出现、要么点不开、默认名 `CaPoo` 不显示、OK 点了没反应。

本项目把它**复活**了：

- 用一段很小的 **引导层（boot shim）** 把原版被掏空的排行榜 / 计分逻辑补齐；
- 让游戏**自带的**名字输入框真正可用（可编辑、可改名、改名后持久化）；
- 重新打包成一个**干净的、可直接安装**的 APK，**开源给大家玩**。

> 我们**没有重写游戏**、没有自己造一套 UI，而是沿用游戏原本的 `role` 数据模型、
> 原本的排行榜面板、原本的 `new_name` 名字输入框，只把"断掉的那根水管"接上。

---

## 二、原版到底哪里坏了（取证过程）

一开始很容易误以为是打包、SDK、权限或存储路径的问题。为了不被表面现象带偏，
我们用 `swfdump -abc`（AIR SDK 自带）对原版 `capoo.swf` 做了完整反编译，
结果非常明确：

**`capoo.swf` 里整段 `flash.data` / SQLConnection 层被掏空了。**

反编译后统计，`capoo_fla:MainTimeline` 有 **9 个方法体只有
`getlocal0; pushscope; returnvoid`（3 字节，空方法体）**，其中包括：

```
Query(String, Function, Function)        ← 核心 SQL 执行
SelectGameDResult / SelectGameDFault     ← 排行榜数据回填
AddGameRowResult / AddGameRowFault       ← 写入新成绩
RunUpdateResult / RunUpdateFault
onOpenHandler / onOpenErrorHandler
```

而真正"有实现"的 `createT()` / `AddGameRow()` / `UpdateGameDResult()` 这几个函数，
在整段 ABC 里**没有任何调用点**——纯死代码。

于是数据链路彻底断掉：

| 原本应该发生的事 | 实际发生的事 |
|---|---|
| `frame1()` 从数据库读出 5 条记录填进 `role` | 全是 `[undefined, undefined]` |
| 排行榜 `frame8()` 写 `name1.text = String(role[0][0])` | 显示 **`undefined`** |
| 主菜单木牌 `hit_point.text = String(role[0][1])` | 显示 **`undefined`** |
| 结束一局时 `if (hit_sum > role[ss][1])` 记录成绩 | `number > undefined` 恒为 `false` → **永远不记录** |

`role` 是一个长度为 5 的数组，每个元素是 `[名字, 分数]` 一对，**用 `ss` / `gsit`
作为索引定位**。只要 `role` 里是 `undefined`，整套逻辑就全死了。

> 顺带一提：原版还带了一个 **AdMob ANE**，但反编译证明它只出现在变量类型声明里，
> 整个字节码没有任何地方调用它的方法——是个**红鲱鱼**，跟排行榜 bug 毫无关系。

---

## 三、修复方案：引导层（boot shim）

我们把引导 SWF 设为 AIR 应用的 `<content>`，由它用 `Loader` 加载游戏本体
`capoo.swf`，然后**只补齐缺失的环节**，绝不替换游戏自己的 UI：

1. **`seedRole()`** — 应用启动时从 `SharedObject`（键名 `capooRank`）读出上次持久化
   的 5 条记录，写进 `role` 的**数值位**。注意：只写值，**绝不重排** `role`
   数组的顺序（顺序由游戏用 `ss`/`gsit` 索引拥有，外部重排会错位把分数清零）。
2. **`recordRoundIfNeeded()`** — 原版把"插入新成绩"的排序逻辑放在 `frame7()`，
   而 `frame7()` 只有**进入游戏帧**时才跑，所以一局结束要等到下一局开始才记录。
   我们在回到主菜单/排行榜/结算帧时，按**原版完全相同的插入语义**先把本局分数插进去，
   置位 `getnew` 标记，并立刻把 `hit_sum` 清零，防止原版 `frame7()` 稍后重复插入同一笔。
3. **`showGameNameClip()`** — 原版的 `new_name` 名字输入框被放在时间轴的
   `x = -609`（屏幕外），而且没有任何代码把它移进来（那段代码原本藏在已失效的
   DB 回调后面）。我们把游戏**自己的**这个 clip 移到屏幕中央、跳到它的 setup 帧，
   让玩家看到"新纪录"弹窗。
4. **`prepareNameField()`** — 游戏自带的 `newname` 文本框有两个毛病：① 它不是输入
   框（`type` 不是 `INPUT`），点它不会聚焦、不会弹键盘；② 它用了**嵌入字体且没有
   拉丁字母字形**，所以 `CaPoo` 这种英文名字渲染出来是空白；③ 它被一个 depth 9 的
   白色圆角方块盖住，文字根本看不见。我们把该字段改成**系统字体 `_sans` 的可编辑
   输入框**、提到最上层、并强制 `stage.focus` + `requestSoftKeyboard()` 弹出软键盘。
5. **`installOkHotspot()`** — 游戏自带的 `ok` 按钮**不能直接用**：它绑定的是
   `go_again()`，而 `go_again()` 反编译出来是这样的：
   ```
   if (newname.text != "") {
       root["over"] = true;
       this.x = -1000;                              // 滑走隐藏
       root["role"][root["gsit"]][1] = newname.text;  // ★★ 写进「分数格」index 1，不是名字格 index 0
       root["lastname"] = newname.text;
   }
   ```
   → 它把**名字写进了分数格**，所以点了 OK 排行榜上还是旧名字；而且在软键盘还挂着
   的时候执行它，正是**游戏崩溃**的元凶。
   我们的做法：保留游戏原本的美术，但把它的 `ok` 设为 `mouseEnabled=false`，
   再用 `getBounds()` 取出按钮的精确位置，盖上一颗**透明 Sprite 熱區**，
   由我们自己处理点击 → **外观是游戏自己的，逻辑走正确的**（写进 index 0）。
6. **`confirmName()` / `applyName()`** — 玩家通过**游戏自己的 OK 按钮**（热区命中）、
   **软键盘的"完成/回车"键**，或 30 秒无操作的兜底时间来确认。确认时读取
   **玩家真正输入在文本框里的文字**，写进 `role[gsit][0]` 并持久化为 `lastname`
   ——**不再是写死成 `CaPoo`**。下次出新纪录时默认名就是玩家上次用的名字。
7. **`syncDisplay()` / `scrubPlaceholders()`** — 把（排序后的）`role` 镜像到
   游戏的 `name1..5` / `scr1..5` / `hit_point` 显示字段，并把残留的 `"undefined"` /
   `"null"` 文本清空。必须用逐帧 `ENTER_FRAME` 同步，否则切到排行榜时新创建的文本
   框会先闪一下作者写的 `"undefined"`。

### 三条稳定性铁律（写在代码注释里，别改坏）

| # | 规则 | 原因 |
|---|---|---|
| 1 | **绝不在鼠标/键盘事件处理器里改显示列表**（`gotoAndStop` / 隐藏 clip / 改焦点） | Android 软键盘挂着时这样操作会让 AIR 运行时崩溃。所有收尾都用 `pendingClose` 旗标**延到下一帧 `ENTER_FRAME`** 再执行 |
| 2 | **绝不让游戏的 `go_again()` 执行** | 它把名字写进分数格；点击由我们自己的热区处理 |
| 3 | **在 stage 上挂 `ErrorEvent.ERROR` 捕获监听器** | 任何未捕捉异常都会被记进日志，**不会再弹 AIR 错误框杀掉 app** |

另外还有两层保险：
- **`repairScoreSlot()`** — 万一 `go_again()` 还是跑了，侦测到分数格变成字符串就
  自动搬回名字格并还原分数，榜单永远不会被写坏。
- **软键盘避让** — 软键盘会盖住屏幕下方约 45%，正好盖住游戏原本的 OK 按钮，
  所以弹出名字面板时会**整体上移**，确保 OK 永远点得到。

> **关于"为什么之前改名还是显示 CaPoo"**：早期版本在弹窗出现时立刻把
> `role[gsit][0]` 写死成 `playerName()`（即 `CaPoo`），并且自动关闭时也不读文本框
> 里玩家实际输入的内容——所以玩家改了也白改。现在改为：**只在确认时读取文本框真实
> 文本**，从而彻底修好。

---

## 四、怎么玩（最快）

直接從 GitHub Releases 下載即可，安裝包已包含遊戲本體，裝完就能玩：

**[下載 capoo-touchhands-revived-v1.0.3.apk](https://github.com/infycat/capoo-touchhands-revived/releases/latest/download/capoo-touchhands-revived-v1.0.3.apk)**

- 安卓 8.0+（API 26+）的 ARM64 设备均可；采用 **captive runtime**，无需另外装 AIR。
- 安裝時若提示「未知來源」，請依 Android 的系統提示操作。本專案以自簽憑證簽署；私鑰不會公開在倉庫中。
- **完全離線**：v1.0.3 起 APK 不再聲明任何權限（`INTERNET`、`ACCESS_NETWORK_STATE` 已移除），
  也不帶 `android:debuggable` 標記，純粹是一個不需要網路、不收集任何資料的離線小遊戲。

### v1.0.3 發佈加固

| 項目 | v1.0.2 | v1.0.3 |
|---|---|---|
| `android:debuggable` | `true` | **移除**（非 debuggable 正式包） |
| `android.permission.INTERNET` | 有 | **移除** |
| `android.permission.ACCESS_NETWORK_STATE` | 有 | **移除** |
| `uses-permission` 總數 | 2 | **0** |

- 敢刪網路權限的理由：整個遊戲**完全離線**。包內附帶的 AdMob ANE 是死碼
  （反編譯後確認它只出現在變數型別宣告裡，位元組碼中從未呼叫過它的任何方法），
  執行時不需要任何網路存取；`adt` 在打包時也會提示
  `Application has not specified its permission requirements`。
- 保留 `uses-sdk`（minSdk 21 / targetSdk 33）不變。
- `versionCode` 由 1000002 升到 1000003，可直接覆蓋安裝舊版。

---

## 五、自行编译（开发者）

### 环境要求

| 工具 | 版本 | 说明 |
|---|---|---|
| Adobe AIR SDK | **51.4.1**（实测） | 提供 `mxmlc` 与 `adt` |
| JDK | **17**（Temurin/OpenJDK） | AIR 51 的 `mxmlc`/`adt` 必须使用 Java 17 |
| 安卓手机 | ARM64 (armv8) | 打包目标架构 |

> ⚠️ 关键坑：AIR 51 运行时对 APK 有**完整性校验**。用 `adt` 打出来的包**不能再**
> 用 `zipalign` / `apksigner` 重签或替换 `assets` 里的文件，否则会触发
> `AdobeAIR: Security warning - invalid license or package - application may have
> been modified` 并自我 `SIGKILL` → 黑屏。**一切修改都必须重新走 `adt -package`。**
> 另外 `adb install` 默认走增量安装也会让 AIR 进入损坏状态，必须
> `adb uninstall` + `adb install --no-incremental`。

### 步骤

```bash
# 1) 准备环境
export AIR_SDK="$HOME/AIRSDK/AIRSDK_51.4.1"   # 指向你的 AIR 51 SDK
#   并确保 JDK 17 在 PATH 上

# 2) 準備你自己的 PKCS#12 簽章憑證（私鑰不可提交到 Git）
export SIGNING_KEYSTORE="$HOME/.keys/capoo-release.p12"
export SIGNING_PASSWORD="你的憑證密碼"

# 3) 编译 + 打包（一条命令）
./build/build.sh          # Windows 用 build\build.bat
```

产物：`dist/capoo-touchhands-revived-v1.0.3.apk`（檔名會自動跟隨 `app.xml` 裡的 `<versionNumber>`）。

安装到手机：

```bash
adb uninstall air.air.capoo
adb install --no-incremental -d dist/capoo-touchhands-revived-v1.0.3.apk
```

---

## 六、目录结构

```
capoo-touchhands-revived/
├── README.md              # 本文件
├── LICENSE                # MIT（仅引导层代码；游戏本体见 LICENSE 内说明）
├── .gitignore
├── src/
│   └── Boot.as            # ★ 复活引导层（核心修复代码，全部逻辑都在这里）
├── assets/
│   ├── app.xml            # AIR 应用描述符（id=air.capoo, 竖屏, 全屏, 零权限）
│   ├── capoo.swf          # 游戏本体（从原版 APK 提取，仅作复活用途）
│   └── icons/             # 36/48/72/96/144/192 px 应用图标
├── build/
│   ├── build.sh           # Linux / macOS 构建脚本
│   ├── build.bat          # Windows 构建脚本
│   ├── e2e_test.sh        # 端到端自动测试（装机 → 打完一局 → 改名 → 点 OK）
│   └── find_ok_center.py  # 从截图中自动定位游戏自己的 OK 按钮
└── dist/                  # 本地建置輸出；正式 APK 發佈於 GitHub Releases
```

> 簽章私鑰**不進倉庫**：`SIGNING_KEYSTORE` / `SIGNING_PASSWORD` 由環境變數提供，
> `assets/capoo.p12` 不存在於版本庫中。

> ⚠️ 构建小坑：`adt` 会把 `<content>` 与图标路径**相对于当前工作目录**解析，
> 所以打包那一步必须 `cd assets` 再执行（`build.sh` / `build.bat` 已经处理好了）。
> 证书与输出路径都要用**绝对路径**，否则 `cd` 之后会找不到文件。

---

## 七、实测验证（Redmi Note 10 5G / Android 11 / AIR 51.4.1）

设备上的运行日志（`ranklog.txt`）节选，带毫秒时间戳：

```
[..229751] RECORDED score=86 gsit=1 role=CaPoo6666/139 CaPoo777/86 ...
[..229771] focus requested text=CaPoo
[..229774] OK hotspot installed at -80.95,32.25 151.2x78.75
[..229774] panel moved to y=201.5 (lift=true)        ← 面板上移，避开软键盘
[..229775] NAME CLIP shown at 240,201.5 size 400.75x300 gsit=1 default=CaPoo
[..232277] STAGE down 286.65,473.35                  ← 玩家点了游戏自己的 OK
[..232278] HOTSPOT down -> confirm
[..232278] CONFIRM requested name=CaPoo22            ← 读的是输入框里的真实内容
[..232299] NAMED role[1][0]=CaPoo22                  ← 21 ms 后写入
[..232300] closed to menu                            ← 23 ms 后关闭
```

| 验证项 | 结果 |
|---|---|
| 排行榜不再显示 `undefined` | ✅ 主菜单木牌与 RANK 面板全部为真实数据 |
| 一局结束自动记录成绩 | ✅ `RECORDED score=86 gsit=1` |
| 名字输入框可编辑、默认名 `CaPoo` 可见 | ✅ 弹出即为可编辑白框，显示当前昵称 |
| 点游戏自己的 OK 按钮 | ✅ **23 ms** 内写入并关闭面板（修复前：毫无反应，要等 10+ 秒） |
| 改名后上榜 | ✅ `NAMED role[1][0]=CaPoo22`，排行榜显示该昵称 |
| 昵称持久化 | ✅ 下局默认名即为上次使用的昵称，重启 app 仍在 |
| 点 OK 崩溃 | ✅ 已修复（见下方铁律 1/2/3） |
| 软键盘挡住 OK 按钮 | ✅ 面板自动上移，OK 永远可点 |

---

## 八、已知限制 / 说明

- **改名持久化**：默认名是 `CaPoo`；玩家在"新纪录"弹窗里可以改成任意名字（最长 10 个字符），
  改名后会写入 `SharedObject` 并作为下次默认名，排行榜也会显示玩家改后的名字。
- **确认方式**（三选一，都可用）：
  1. 点游戏自己的 **OK 按钮**（我们用透明热区接管点击，外观与行为都由游戏自己呈现）；
  2. 按软键盘的**完成 / 回车**键；
  3. 30 秒无操作自动确认（兜底）。
- **`role` 不被外部重排**：排行榜的排序展示由引导层在副本上完成，真实 `role` 数组的顺序
  始终由游戏本体用 `ss`/`gsit` 索引维护，避免分数被清零（这是早期版本踩过的坑）。
- **输入法提示词**：部分中文输入法在输入框获得焦点时会自动填入候选词，这是系统
  输入法的正常行为，玩家可自行删除。
- **游戏本体版权**：`capoo.swf` 与美术资源归原作者所有，本仓库只提供开源的复活引导层与
  构建工具，属于粉丝向的"抢救 + 可玩化"复刻，不构成对游戏本身的权属主张。

---

## 九、许可证

引导层源码（`src/Boot.as`、构建脚本）采用 **MIT License**。

游戏本体 `capoo.swf` 及美术资源的版权归**原作者**所有，详情见 [LICENSE](./LICENSE)。
本仓库仅用于已断更游戏的保存与复玩。

完整的復活流程、資料流、修復腦圖與技術決策請見
[`docs/REVIVAL.md`](./docs/REVIVAL.md)；版本變更見 [`CHANGELOG.md`](./CHANGELOG.md)。
