# ADR-1158：拖放层（kl3 DragEvent / ame / ol3）

## 状态

已接受（Phase 1214）。

## 决策

`kl3`=`DragEvent` 包装 + `pl3` 6 回调 + `ame` 接收器
（P0 读 ClipData）+ `ol3` 树派发 → Harmony `onDrop`/
`DragEvent` + `unifiedDataChannel`（拖文本/图片/链接）。

## 理由

`ame{DragEvent, getClipData/getClipDescription/getX/Y}`
+ `pl3` F/P0/k0/u0/w0/x 对应 6 DragEvent 动作 +
`ol3` od8 树路由 —— 完整拖入接收管线。

## 后果

Harmony 笔记拖入 = 组件 onDrop + UDC 数据解析 —
拖文本/图片/链接入笔记对齐原版。
