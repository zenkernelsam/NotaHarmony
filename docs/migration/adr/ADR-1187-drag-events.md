# ADR-1187：bq1/bq4 拖拽事件

## 状态

已接受（Phase 1243）。

## 决策

`bq1` drag summon（zo4/ap4）+`bq4` focus relay+`j1`
emit → Harmony `onDrop`/`onDragStart`+focus 事件。

## 理由

`bq1`=drag&drop summon（"Drag & Drop"协程+`ns`）；
`bq4`=focus-relay Node（`xp4` onFocusStateChange+
`j1(wj8,t76)` emit `ap4(zo4)`）—— zo4/ap4 拖拽
start/end。

## 后果

Harmony 拖拽 = onDragStart/onDrop+focus —— 拖拽
事件语义保真。
