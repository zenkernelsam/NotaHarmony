# ADR-1224：MyScript iink + Play 授权（vendor SDK）

## 状态

已接受（Phase 1280）—— **fail-closed**。

## 决策

MyScript iink 手写识别 → Harmony 无移植，fail-closed
到系统 handwriting/ML Kit 回退或禁用；pairip Play
授权/完整性 → Harmony 无对应，省略校验。

## 理由

`com.myscript.iink`（94 文件：Engine/Editor/
OffscreenEditor/ContentBlock —— 手写→文本/数学/
图形识别，商业 SDK+原生库）—— Harmony 无 MyScript
移植；`com.pairip`（LicenseClient/Activity/Integrity —
— Play 反盗版）—— Harmony 无 Play 授权概念。

## 后果

Harmony 手写识别 = 系统 handwriting 或特性降级；
完整性校验 = 省略 —— 商业 SDK fail-closed。
