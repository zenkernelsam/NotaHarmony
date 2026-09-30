# Phase 1394 证据 — 放大窗 `zoomViewSourceRect`/`zoomViewShown` 持久化与恢复

> 源码证据：`decompiled_1.4.2`（1.4.2 APK，v1040002）。Phase 1393 已把两列
> 补进 `note_state` 保 round-trip；本 Phase 把行为接上——原版按笔记持久化
> 放大窗源矩形与显隐，重开笔记恢复面板原位。

## 1. 原版写路径（wmb.java / ymb.java）

`wmb` 持有两条专属 UPDATE（bz5 回调持有者与参数见文件）：

```java
// wmb.java:75   — isShown 专属写
"UPDATE NoteStateEntity SET zoomViewShown = ? WHERE id = ?"
// wmb.java:102  — sourceRect 专属写
"UPDATE NoteStateEntity SET zoomViewSourceRect = ? WHERE id = ?"
```

`ymb.java` 是 note_state 写门面：61/119/213/272/330 行各构造只带单字段的
`anb`（mask 62/118/120/94/110）走 `a(anb, qs2)` 局部更新——zoom/scroll、
lastCodeBlockLanguage、isTextOnly、sourceRect、shown 各有专属写，互不动列。

## 2. 原版读/恢复路径

- `ws3.java:295` — `SELECT zoomViewShown FROM NoteStateEntity where id = ?`
  按笔记单读 shown；同文件 case 邻位有 sourceRect 单读（232-233）。
- `chb.java:45-46` — 整行读 `zoomViewSourceRect`/`zoomViewShown`。
- `anb.java` — `NoteStateEntity` 域模型，`e`=sourceRect(`sbe`)、
  `f`=shown(Boolean)、`g`=isTextOnly。
- `kck.java:69` — `ZoomViewState(isShown, dockEdge, sourceRectDocPx,
  magnification, advanceRegionWidthDp, panelInTopHalf)`；
  `rck.java:19` 初值 `kck(false, vak.G, sbe.e, 5.0f, 180.0f, false)`——
  **初值是默认**，持久化值经由 note-state 收集器灌回（恢复链路存在）。
- `kdk.java:46-54` — `A()` 隐窗 `kck.a(…, mask=62)` 仅清 isShown，
  **sourceRect 会话内保留** → 隐/显切换不丢位置。

## 3. 序列化格式

`ten.java:103` `r(sbe)` = `"a,b,c,d"`（left,top,right,bottom float 逗号串）；
`ten.java:118` `y(str)` 解析失败回落 `sbe.e`=(0,0,0,0)。

## 4. Harmony 接入（本 Phase）

| 原版 | Harmony 实现 |
|------|--------------|
| `zoomViewSourceRect` UPDATE（wmb:102） | `saveZoomViewSourceRect`（NoteRepositoryImpl，`getViewState`→改字段→`saveViewState` 全量回写，保留列不丢） |
| `zoomViewShown` UPDATE（wmb:75） | `saveZoomViewShown` 同模式 |
| `ten.r` `"l,t,r,b"` | `persistZoomViewSourceRect` 序列化 `l,t,l+w,t+h` |
| `ten.y` 空/非法→`sbe.e` | `parseZoomSourceRect` 四元 + `r>l && b>t` 校验，非法→null 回落锚定 |
| ZoomViewState 会话内保留 sourceRect（kdk.A mask62） | `restoredZoomSourceRect` 内存镜像：持久化即更新，`initZoomSourceRect` 恒优先恢复 → 隐/显、切页均回原位 |
| `zoomViewShown` 恢复（ws3:295 读） | `loadNoteData` 载入 shown=true 且当前非 ZOOM → `selectTool(ZOOM)` 重挂面板 |
| isShown 隐窗/显窗写 | 面板 `onAppear`→写 true；`onDisAppear`→按当时 `currentTool===ZOOM` 写（Close/换工具=false；整页导航离开保持 true，等价原版关笔记仍存 shown） |

持久化落点（覆盖全部 sourceRect 变更）：`endZoomWindowDrag`（窗拖/把手
resize/边缘滚动/卸载共用出口）、`zoomStepBack`/`zoomStepForward`、
`zoomAutoAdvance`（仅真前进时）、`zoomReturnToInk`（仅真回位时）。

**不持久化**：`magnification`/`dockEdge`/`panelInTopHalf`——`ca3.java:519`
`NoteStateEntity` 无对应列，原版同样不持久化（会话内默认）。

## 5. 行为差异声明

- `initZoomSourceRect` 原「每次挂载锚定末笔」改为「有持久化位 → 恢复原位；
  无 → 末笔/视口中心回落」。依据 `kck.a mask62`：原版隐窗不清 sourceRect，
  续用旧位才是原版语义。
- 恢复仅取 l,t；r,b 不取（宽高随当前 magnification/面板尺寸重算）——
  原版持久化的亦是 rect 四值，恢复时尺寸经当前 magnif 重算等价。
