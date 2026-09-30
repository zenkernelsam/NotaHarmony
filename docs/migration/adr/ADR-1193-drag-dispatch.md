# ADR-1193：ol3/pl3/kl3 拖拽分发

## 状态

已接受（Phase 1249）。

## 决策

`ol3` 分发树+`pl3` iface+`kl3` DragEvent+`ame` 5-λ →
Harmony `onDrop`/`onDragEnter`/`onDragLeave`/`onDragMove`
+`getData`。

## 理由

`ol3`=`od8` 分发 Node（`P0`/`F`/`k0` 树遍历→`ol3 X`/
`pl3 Y`）；`pl3`=DragEvent 回调；`ame`=`P0` 读 ClipData
—— 拖拽分发。

## 后果

Harmony 拖拽 = onDrop/onDrag+getData —— 分发语义
保真。
