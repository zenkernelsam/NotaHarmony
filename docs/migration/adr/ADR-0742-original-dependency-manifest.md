# ADR-0742 — 原版 1.4.2 依赖清单差与 multidex 登记

日期：2026-09-29
状态：已登记（依赖面闭合；无源码变更）
证据：`docs/migration/evidence/phase-798-original-dependency-manifest.md`
Replay：`docs/migration/replays/d02-original-dependency-manifest.mjs`

## 背景

META-INF `*.version` 清单差唯一新增 androidx.ink:
ink-storage；dex 3→4。

## 决策

- ink-storage 归 762/776 笔刷包簇（Google Ink brush
  family 持久化）；本体为 AndroidX 库不移植。
- 修正认知：Ink 引擎六件自 1.0.3 已内置——1.4.2 仅增
  存储件；Harmony 自研笔触管线对应 authoring/rendering/
  strokes 层已由既有实现承担。
- dex/kotlin_module 差为打包事实，无行为面。

## 后果

- 依赖清单面闭合；1.4.2 证据七维全部归属。
