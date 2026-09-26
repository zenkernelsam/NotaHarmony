# ADR-0722 — 原版 1.4.2 钢笔增强面登记（书法笔尖/样式标签/防抖）

日期：2026-09-29
状态：已登记（版本差·本地候选；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-778-original-pen-enhancements.md`
Replay：`docs/migration/replays/d02-original-pen-enhancements.mjs`
上游：ADR-0711、ADR-0720、Phase 762（brushpack）

## 背景

1.4.2 为钢笔新增书法笔尖（`qx5`/`px5`/`ox5`：angle+flatness
几何）、防抖开关（`stabilization` 列 + 选项面板行）、笔刷样式
本地化标签（fixed/variable/dashed/dotted），并把 `style` 列从
INTEGER 迁移为 TEXT。

## 决策

1. **书法笔尖 + 防抖**：纯本地笔画几何与参数开关——版本差·
   本地候选；回移与否独立评审（1.0.3 基线不含）。
2. `style` INTEGER→TEXT 为原版内部序列化迁移，Harmony 无需对应。
3. 本阶段不实现——Harmony 的 BrushStyle（MONO/TAPER/DASH/DOT）
   维持 1.0.3 对齐。

## 后果

- 钢笔增强规格（默认 angle=π/2、flatness=0、18 列 DAO 读写面）
  进入 T-042 输入。
- Replay 钉住八条键、nib 类族、三新列与类型迁移。
