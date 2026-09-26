# ADR-0735 — 原版 1.4.2 非字符串资源面收尾登记

日期：2026-09-29
状态：已登记（vendor 裁剪 + 既有簇资产；无源码变更）
证据：`docs/migration/evidence/phase-791-original-nonstring-resources.md`
Replay：`docs/migration/replays/d02-original-nonstring-resources.mjs`

## 背景

字符串面收尾（Phase 790）后，补齐非字符串资源面的
全量归属：res/ 目录结构、raw/font、drawable/nodpi。

## 决策

- values-*/layout-*/color-* 桶裁剪：vendor 资源裁剪
  （Compose 化+依赖升级），无应用行为差。
- res/raw 两版一致；res/font 仅 Inter 可变字体轴差。
- drawable 新增全部归属既有簇；移除项均为换键
  （convert_to_math 等经代码核实仍在）。
- nodpi covers/planner/glitter 归属 762/763/782 簇。

## 后果

- 1.4.2 `resources/res/` 全量归属完毕：字符串 +722 键
  （Phase 760-790）+ 非字符串面（本阶段）。
- 剩余未注册面集中于类级差（Room/工作器/服务）与资产面，
  均已按簇登记。
