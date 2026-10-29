# Capoo 摸摸手（Capoo touch）原版玩法保存版 v1.0.4

[繁體中文](README.md) · **简体中文** · [English](README.en.md)

## 直接下载

**[下载 Android APK](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-universal.apk)** · **[下载 Windows x64 ZIP](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-win-x64.zip)** · [完整源码 ZIP](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginalSource-v1.0.4.zip)

正式成品均放在 GitHub Release：

| 平台 | 下载资源 | 说明 |
| --- | --- | --- |
| Android | [CapooOriginal-v1.0.4-universal.apk](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-universal.apk) | 通用 APK，内含 AIR runtime |
| Windows x64 | [CapooOriginal-v1.0.4-win-x64.zip](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-win-x64.zip) | 解压后运行 CapooOriginal.exe；内含 AIR runtime |
| 完整源码 | [CapooOriginalSource-v1.0.4.zip](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginalSource-v1.0.4.zip) | AS3 源码、平台适配、图标、构建脚本和文档 |
| 校验文件 | [SHA256SUMS.txt](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/SHA256SUMS.txt) | 校验三个发布文件 |

[打开 v1.0.4 Release](https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.4)

> 社区保存与兼容性重建版本，非 Carter Island Studio 官方新版。本版以完整原版 ActionScript 3 游戏逻辑制作，提供 Android 与 Windows 版本。

## 为什么重建

《Capoo touch／Capoo 摸摸手》是 Carter Island Studio 推出的旧 Android 游戏。第三方历史目录记录的官方包名为 <code>air.capoo</code>、最终可查版本为 1.0.1，并记载 2018 年下架；这不代表工作室发布过停运公告：[AppBrain 历史记录](https://www.appbrain.com/app/capoo-touch/air.capoo)、[APKCombo 版本记录](https://apkcombo.com/capoo-touch/air.capoo/)。

原版依赖较旧的 Adobe AIR 与当时的 Android 兼容环境。随着 Android 系统、处理器架构和 runtime 政策变化，一些新设备可能无法直接安装或启动。此项目从完整原始 AS3 与 SWF 资源重建，通过 AIR captive runtime 随包提供运行时；Android target API 36，含 ARM64、ARMv7、x86 和 x86_64。

## 版本关系与玩法

v1.0.3 是早期复活版，基于原 SWF 加入小型引导层，修补排行榜及结算输入流程。它的源码、文档、Git tag 和 APK Release 均保留：[v1.0.3 README](https://github.com/infycat/capoo-touchhands-revived/blob/v1.0.3/README.md)、[v1.0.3 Release](https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.3)。

v1.0.4 是独立的新版本，直接重建完整原版 AS3 时间轴和玩法流程。手机用原始 TouchEvent；Windows 增加鼠标事件适配，仍调用同一组六个玩法处理器。计分、连击、计时、动画、结算、经验值和本地排行榜都予以保留。

## 结构与玩法数据

~~~mermaid
flowchart LR
  A[17 个原版 AS3 类] --> B[swf-toolkit 重建]
  C[原版 SWF 与美术] --> B
  B --> D[Android TouchEvent SWF]
  B --> E[Windows MouseEvent SWF]
  D --> F[AIR captive runtime] --> G[Universal APK]
  E --> H[AIR bundle] --> I[EXE + runtime ZIP]
~~~

~~~mermaid
mindmap
  root((Capoo 1.0.4))
    完整原版玩法
      六个拍手区域
      计分与连击
      计时与结算
      本地 SQLite 前五名
    平台适配
      Android 触控
      Windows 鼠标
      AIR runtime 随包提供
    发布资源
      APK
      Windows ZIP
      完整源码 ZIP
      SHA-256 校验
~~~

| 数据项 | 游戏逻辑 |
| --- | --- |
| 输入区域 | 左右各三处，共六处拍手区域 |
| 计时 | 初始 100 个 100 ms 刻度；正确命中按进度增加 1–2 格 |
| 连击 | 命中达到 20、50 时切换阶段，内部加分值为 51、203、302 |
| 背景阶段 | 命中达到 50、100、200 时推进背景状态 |
| 本地排行 | SQLite <code>gamed</code> 表保存前五名姓名和分数 |
| 分数用途 | 画面显示命中数；内部 score 用于经验值和进度 |

完整数据分析、启动流程与思维导图见 [繁体中文版架构说明](README.md#遊戲與程式結構) 和源码 ZIP 中的 <code>docs/ARCHITECTURE.md</code>。

## 安装、签名与验证

- Android application ID：<code>air.air.capoo</code>；版本 1.0.4，versionCode 1000004。
- 最低 Android API 23，target API 36；支持 arm64-v8a、armeabi-v7a、x86、x86_64。
- Manifest 权限数为 0；Android APK 和 Windows ZIP 均包含 AIR runtime。
- APK SHA-256：<code>F2A96567A1427F3C97D3A9F61002252075A3EC29699552F29A44621570D14700</code>。
- Windows ZIP SHA-256：<code>4C7675BD283826FE89E7EF510E8C58E99C04332AA9C8247F35EC0C4A1CA0D02D</code>。
- 新长期证书 SHA-256：<code>806e00840b245c1f6a430e6ae2aae1d064cde8b078bc2ff224f8f5173a8ba1d8</code>。

由于拿不到原版签名私钥，1.0.4 使用新证书签名，不能直接覆盖原版或 1.0.3。安装前需卸载旧版；卸载会清除本地排行榜。之后更新必须一直使用同一私钥。发布文件不含私钥或密码。

使用者已确认游戏功能测试通过。正式 APK 的包名、版本、target、ABI、零权限、图标及签名均已由构建流程检查；完整记录见源码 ZIP 的 <code>TEST-REPORT.md</code>。

## 源码与版权

源码包包含 17 个原版 AS3 类、Android 与 Windows 平台副本、图标、SWF 重建工具和 AIR 打包脚本。重建需要 Node.js 18+、锁定版 swf-toolkit、AIR SDK 51.4.1.x、JDK 17 和 Android SDK platform 36。

原作名称、美术、音效、SWF 和 AS3 源码的权利仍归原权利人。本项目用于保存和兼容性重建，不主张拥有原作。仓库 MIT 声明仅按其原文适用于旧版复活引导层和构建工具，并未扩展到原作素材。参见 <code>COPYRIGHT.md</code>。
