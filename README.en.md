# Capoo touch — Original Gameplay Preservation v1.0.4

[繁體中文](README.md) · [简体中文](README.zh-CN.md) · **English**

## Downloads

**[Download Android APK](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-universal.apk)** · **[Download Windows x64 ZIP](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-win-x64.zip)** · [Full source ZIP](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginalSource-v1.0.4.zip)

All release artifacts are attached to GitHub Releases:

| Platform | Download | Notes |
| --- | --- | --- |
| Android | [CapooOriginal-v1.0.4-universal.apk](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-universal.apk) | Universal APK with captive AIR runtime |
| Windows x64 | [CapooOriginal-v1.0.4-win-x64.zip](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginal-v1.0.4-win-x64.zip) | Extract the ZIP and run CapooOriginal.exe; AIR runtime is included |
| Full source | [CapooOriginalSource-v1.0.4.zip](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/CapooOriginalSource-v1.0.4.zip) | AS3 source, platform adaptations, icons, build scripts and documentation |
| Checksums | [SHA256SUMS.txt](https://github.com/infycat/capoo-touchhands-revived/releases/download/v1.0.4/SHA256SUMS.txt) | Verify the three release assets |

[Open the v1.0.4 Release](https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.4)

> A community preservation and compatibility rebuild, not an official Carter Island Studio release. Version 1.0.4 rebuilds the complete original ActionScript 3 gameplay for Android and Windows.

## Why this rebuild exists

Capoo touch was an older Android game by Carter Island Studio. Third-party historical catalogs list the original package as <code>air.capoo</code>, version 1.0.1 as the last known release, and record that it was unpublished in 2018. These catalog entries are not an official studio shutdown statement: [AppBrain history](https://www.appbrain.com/app/capoo-touch/air.capoo), [APKCombo version record](https://apkcombo.com/capoo-touch/air.capoo/).

The original depended on an older Adobe AIR and Android environment. Changes to Android, processor architectures and runtime policies can prevent installation or startup on some modern devices. This project rebuilds the complete original AS3 and SWF input and ships AIR as a captive runtime. The Android package targets API 36 and contains ARM64, ARMv7, x86 and x86_64 libraries.

## Version history and gameplay

v1.0.3 was the earlier revival: it kept the original SWF and added a small boot shim to repair leaderboard and name-entry flows. Its source, documentation, Git tag and APK release remain available: [v1.0.3 README](https://github.com/infycat/capoo-touchhands-revived/blob/v1.0.3/README.md), [v1.0.3 Release](https://github.com/infycat/capoo-touchhands-revived/releases/tag/v1.0.3).

v1.0.4 is a separate new version rebuilt from the complete original AS3 timeline and gameplay. Android uses the original touch handlers. Windows adds a mouse adapter that calls the same six gameplay handlers. Scoring, combos, timer, animations, results, experience and the local leaderboard are retained.

~~~mermaid
flowchart LR
  A[17 original AS3 classes] --> B[swf-toolkit rebuild]
  C[Original SWF and artwork] --> B
  B --> D[Android TouchEvent SWF]
  B --> E[Windows MouseEvent SWF]
  D --> F[Captive AIR runtime] --> G[Universal APK]
  E --> H[AIR bundle] --> I[EXE + runtime ZIP]
~~~

~~~mermaid
mindmap
  root((Capoo 1.0.4))
    Original gameplay
      Six clap zones
      Scoring and combos
      Timer and results
      Local SQLite top five
    Platform adapters
      Android touch
      Windows mouse
      Bundled AIR runtime
    Release files
      APK
      Windows ZIP
      Full source ZIP
      SHA-256 checksums
~~~

## Gameplay data

| Item | Existing game logic |
| --- | --- |
| Input areas | Six clap zones, three on each side |
| Timer | Starts at 100 ticks of 100 ms; correct hits add 1–2 ticks by progress |
| Combo | Tiers change at 20 and 50 hits; internal score increments are 51, 203 and 302 |
| Background | Progress states at 50, 100 and 200 hits |
| Local ranking | SQLite <code>gamed</code> table stores five name/score pairs |
| Score use | The result screen displays hit count; internal score feeds experience/progress |

The source ZIP contains the full architecture map, mind map and detailed analysis in <code>docs/ARCHITECTURE.md</code>.

## Installation, signing and verification

- Android application ID: <code>air.air.capoo</code>; version 1.0.4; versionCode 1000004.
- Minimum Android API 23; target API 36; ABIs: arm64-v8a, armeabi-v7a, x86 and x86_64.
- The manifest requests no permissions. The APK and Windows ZIP include AIR runtime.
- APK SHA-256: <code>F2A96567A1427F3C97D3A9F61002252075A3EC29699552F29A44621570D14700</code>.
- Windows ZIP SHA-256: <code>4C7675BD283826FE89E7EF510E8C58E99C04332AA9C8247F35EC0C4A1CA0D02D</code>.
- New permanent certificate SHA-256: <code>806e00840b245c1f6a430e6ae2aae1d064cde8b078bc2ff224f8f5173a8ba1d8</code>.

The original signing key could not be unlocked, so v1.0.4 uses a new certificate and cannot update an existing original or v1.0.3 install in place. Uninstall the older app first; uninstalling clears its local leaderboard. Future updates must use the same new key. The release does not contain the private key or password.

The user confirmed that gameplay testing passed. The release build checks the package identity, version, target API, ABIs, zero permissions, icons and signer. Detailed records are in <code>TEST-REPORT.md</code> inside the source archive.

## Source and rights

The source archive contains the 17 original AS3 classes, Android and Windows platform copies, icons, SWF rebuild tools and AIR packaging scripts. Rebuilding requires Node.js 18+, the locked swf-toolkit dependency, AIR SDK 51.4.1.x, JDK 17 and Android SDK platform 36.

Rights to the original name, artwork, audio, SWF and AS3 source remain with their respective owner. This is a preservation and compatibility rebuild, not a claim of ownership. The repository MIT notice applies only as stated to the earlier revival shim and build tools; it does not license original game assets. See <code>COPYRIGHT.md</code>.
