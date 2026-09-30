# ADR-1192：u8e pointerInput 节点

## 状态

已接受（Phase 1248）。

## 决策

`u8e` pointerInput+`bra`/`r93`/`ara`+`PointerInputEventHandler`
协程 → Harmony `onTouch`+组件 state+协程。

## 理由

`u8e`=`od8` Node 跑 PointerInputEventHandler 协程，
`iqa a0`+`ql8`×3+`f0` downTime+`PointerInputResetException`
—— pointerInput scope。

## 后果

Harmony 指针 scope = onTouch+state+协程 —— 指针
scope 语义保真。
