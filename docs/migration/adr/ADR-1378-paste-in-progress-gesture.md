# ADR-1378: 进行中套索手势上的粘贴不产选区（j01 hsf→null）

- 状态：已接受
- 日期：2026-08-09
- 关联：ADR-1374（supportsDeselectMode 种类标记）、ADR-1375/1376

## 背景

原版 `j01` 粘贴结果选区回调对 `hsf`（进行中套索）返回 `null`——
内容照插但不产选区。Harmony 粘贴点以 `selectionVisible` 判保种，
进行中手势 `selectionVisible=false` → 走集合型断言 → 误产 isf 选区。

## 决策

`SelectionTool` 新增 `isSelectionGestureInProgress()` =
`isActive && 六类 id 全空`；两处粘贴落点以此为门跳过
`selectElementIds`，等价原版 null 选区结果（手势态保持，
其后 finalize 自决）。

## 后果

- 进行中套索+键盘粘贴的边角态与原版一致：内容插入、无选区断言。
- 正常路径不变（isf/lsf/jsf 保种语义经 `selectionVisible` 维持）。

## 验证

`d02-paste-in-progress-gesture.mjs` 9/9；基线+双构建见提交。
