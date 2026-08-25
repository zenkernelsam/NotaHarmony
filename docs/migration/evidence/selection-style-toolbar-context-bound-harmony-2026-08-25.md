# Harmony 证据：选区样式工具栏上下文绑定

- 日期：2026-08-25
- 缺陷：Canvas 已向 NotePage 回传选中颜色、宽度、范围和 Taper 可用性，但不回传选中 Ink 样式；
  `selectionInkStyle` 只保留用户点击后的值并初始化为 FIXED_WIDTH。选择已有笔迹时工具栏无法回显 MONO/Taper/Dash/Dot。
- 修复：新增 `inkStyleToBrushStyle()` 反向映射；Canvas 在同一 selection-controls 回调中按现有“第一个非 partial
  笔迹”策略提取 `renderSpec.inkStyle` 并回传；NotePage 同步状态后传给 EditorToolbar。
- UI：四个选区样式按钮使用当前上下文高亮，不再全部显示普通底色；铅笔选中仍禁用 Taper。
- 静态验证：ArkTS 四个触点无错误（既有 warning/info 不计）；专项 Replay 通过。
