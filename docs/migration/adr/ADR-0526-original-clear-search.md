# ADR-0526: 原版搜索清空按钮

日期：2026-09-22（Phase 555）

## 背景

原版库搜索栏在查询非空时提供 "Clear search" 图标按钮；Harmony 的搜索
`TextInput` 缺少清空入口，用户需手动删字符。

## 决策

- 用 ArkUI 原生 `cancelButton({ style: CancelButtonStyle.INPUT })`：有文本
  时显示 X，点击清空并触发 `onChange('')`，复用既有防抖重载管线。
- 不自绘图标按钮：原生组件已具备点击清除语义，自绘需额外同步文本状态。

## 差异登记

- 原版为 28dp 常态图标按钮（查询非空即显示）；Harmony `INPUT` 风格在输入
  态显示，且无独立无障碍标签——登记为平台适配差异。

## 备选

- Row 尾部叠加自定义 X 按钮：需手动同步 `searchText`/`TextInput.text`
  双向绑定，复杂度高于原生属性，弃用。
