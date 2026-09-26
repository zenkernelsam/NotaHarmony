# ADR-0740 — 原版 1.4.2 深链与 intent-filter 差登记

日期：2026-09-29
状态：已登记（版本差；无源码变更）
证据：`docs/migration/evidence/phase-796-original-deeplink-delta.md`
Replay：`docs/migration/replays/d02-original-deeplink-delta.mjs`

## 背景

manifest autoVerify 深链集差：`/gallery` pathPrefix +
`/event/planner2627` 精确路径为 1.4.2 新增。

## 决策

- `/gallery` 归 774 画廊社交簇（深链入口）。
- `/event/planner2627` 归 782 计划本营销簇。
- 两条深链均不独立移植：Harmony 已登记 /event/* 营销族
  与 /authlink fail-closed；/gallery 随画廊簇 fail-closed
  （无后端）。module.json5 暂不加 uris 条目（无效目标
  不声明）。
- 其余 intent-filter（PDF/msauth/HWR 服务声明/前台服务）
  两版一致或已登记。

## 后果

- manifest 面闭合（组件 784 + 深链 本阶段）。
