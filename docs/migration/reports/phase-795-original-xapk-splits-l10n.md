# Phase 795 — 原版 1.4.2 XAPK 分包与本地化面

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-795-original-xapk-splits-l10n.md`
ADR：`ADR-0739-original-xapk-splits-l10n.md`
Replay：`d02-original-xapk-splits-l10n.mjs`（6/6）

## 本阶段做了什么

直接解析两份 XAPK 中央目录与 manifest.json，登记分包
结构与本地化面。

## 发现

- 1.0.3=4 split；1.4.2=base+17 语言 split+stickers+
  density/ABI（共 22 entry，393MB）。
- 语言 split 含真实编译 arsc（zh 包 205KB）——非占位。
- manifest.json：minSdk 32 / targetSdk 36。
- Harmony 侧 zh_CN 已 649/652 近全量；其余 15 语种为
  版本差资源缺口。

## 验收

- Replay 6/6 绿；XAPK 分层面闭合；全量套件与双 HAP
  随本阶段执行。
