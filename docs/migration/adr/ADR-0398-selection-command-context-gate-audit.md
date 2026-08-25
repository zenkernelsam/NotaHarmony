# ADR-0398：选区命令上下文门禁补审

## 状态

已接受（2026-08-25，Phase 421）。

## 背景

Phase 418～420 修复了选区退出、替换和临时编辑器后的状态一致性。补审需要确认剩余入口是否存在同类缺口：
Math 编辑、图片裁剪、Ink 样式/颜色/宽度命令是否可能消费空选区或非 Selection 工具下的陈旧寄存器。

## 决策

1. Math 编辑入口继续由 `selectionCanEditMath` 门禁。该能力在浮层刷新时要求恰好一个 canonical Math ID，
   且不能混入其他实体或组；入口再次校验 Math 存在与 operation identity，避免 stale capability 直接进入编辑器。
2. 图片裁剪入口由 `startImageCrop()` 再次调用 `canCropImageSelection()` 校验；该函数要求除单张图片外无任何实体，
   并重新解析图片与 crop session。
3. Ink 命令统一走 `modifySelectedInkRegisters()`。入口要求 loaded、非 history busy、当前工具为 Selection；
   随后直接从 SelectionTool 读取 stroke/shape IDs，不依赖 NotePage 的显示寄存器判断命令目标。
4. 本阶段不改运行行为，只把上述不变量固化为 Replay 断言，防止后续重构移除二次门禁或改为消费显示态寄存器。

## 后果

原版 1.0.3 中 `itc` 表示单元素 Tap 选中，`dhb` case 13 从当前 Tap state 取 Math block 后发布 `x08.Edit`，
case 12 的 style popover 也从 `xsc` 当前选择派生操作集合；这支持“能力/目标必须在入口从当前 selection 派生”的语义。
Harmony 现有实现符合该边界。Phase 421 作为审计收口阶段记录证据并加强专项 Replay。
