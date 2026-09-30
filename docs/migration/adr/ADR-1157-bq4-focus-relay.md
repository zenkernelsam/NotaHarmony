# ADR-1157：bq4 焦点/事件中继节点

## 状态

已接受（Phase 1213）。

## 决策

`bq4` FocusEventModifierNode + `requestFocus` 语义 +
`t76` 中继（重绑补 `ap4`）→ ArkUI `focusable`/
`focusControl` + `onFocus` 回调 + 事件转发补结束事件。

## 理由

`bq1` onFocusStateChange 方法引用 + `ivc.w`
RequestFocus 语义 + `j1` trySend/挂起 emit +
`k1` 重绑补结束 —— 焦点与手势对账集成。

## 后果

Harmony 编辑器焦点 = focusable + onFocus +
t76 转发（通道切换时结束事件补齐保持对账）。
