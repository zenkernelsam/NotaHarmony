# Phase 1214 证据 — 拖放层（kl3=DragEvent / pl3 监听 / ame 接收 / ol3 派发）

来源：`defpackage/{kl3,pl3,ame,ol3}.java`。

## `kl3` = `android.view.DragEvent` 包装

`kl3{a: DragEvent}` —— `pl3` 的 6 回调对应
DragEvent 6 动作：

| pl3 方法 | DragEvent 动作 | ame 处理 |
|---|---|---|
| `F(kl3)` | DRAG_STARTED | `N.invoke` |
| `P0(kl3)` | **DROP** | `I.invoke` + `getClipData()`/`getClipDescription()` 读取 |
| `k0(kl3)` | DRAG_ENDED | `M.invoke` |
| `u0(kl3)` | DRAG_ENTERED | invoke |
| `w0(kl3)` | DRAG_LOCATION | `getX/getY` 位置 |
| `x(kl3)` | DRAG_EXITED | `K.invoke` |

## `ame` = 拖放接收器（5+1 lambda）

`ame implements pl3` —— `qle`×5 + `crb`/`ew` 包装：
drop（取 ClipData→文本/图像/链接）、dragStarted/
dragEnded/dragEntered/dragExited/dragLocation —
即**拖内容进笔记**的接收点（`ls` 的 `ClipData "link"`
对齐 —— 拖入链接/图片）。

## `ol3` = 拖放派发节点

`ol3 extends od8 implements vff,pl3,kv6 {pl3 Y; ew W}` —
`P0`/`F`/… 沿 `od8` 子树分发到 `pl3` 实现 —
drag 事件的 Modifier.Node 路由层。

## Harmony 决策

`DragEvent`/`ClipData` → Harmony `onDrop`/
`DragEvent` + `unifiedDataChannel`（拖文本/图片/
链接入笔记）；`ol3` 树派发 → 组件级 drop 处理。

## 产出

- fixture `d02-drag-drop.mjs`（10 断言）。
- ADR-1158；中文报告。
