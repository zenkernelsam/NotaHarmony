# Phase 798 — 原版 1.4.2 依赖清单差与 multidex

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-798-original-dependency-manifest.md`
ADR：`ADR-0742-original-dependency-manifest.md`
Replay：`d02-original-dependency-manifest.mjs`（4/4）

## 本阶段做了什么

解析两版 XAPK→base.apk 的 META-INF/*.version 清单与
dex/kotlin_module 目录，完成依赖面归属。

## 发现

- .version 129→130，唯一新增 androidx.ink:ink-storage
  ——与 googleInkBrushPackId/.brushpack 闭环（笔刷包
  持久化）。
- AndroidX Ink 引擎六件自 1.0.3 已内置；1.4.2 仅加
  存储件。
- classes.dex 3→4；kotlin_module 4→4。

## 验收

- Replay 4/4 绿；依赖面闭合（七维证据完成）；全量
  套件与双 HAP 随本阶段执行。
