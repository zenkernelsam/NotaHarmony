# Phase 1394 报告 — 放大窗 `zoomViewSourceRect`/`zoomViewShown` 持久化与恢复

- 阶段：1394
- ADR：ADR-1330
- 证据：`docs/migration/evidence/phase-1394-original-zoom-view-state-persist.md`
- Replay：`docs/migration/replays/d02-original-zoom-view-state-persist.mjs`（20 检查）

## 背景

Phase 1393 把 `zoom_view_source_rect`/`zoom_view_shown` 补进 `note_state`
作 round-trip 保列。本 Phase 接上原版行为：原版按笔记持久化放大窗源矩形
与显隐（`wmb.java:75/102` 专属 UPDATE、`ws3.java:295` 恢复读），重开笔记
恢复面板原位。Harmony 此前每次挂载重锚定（末笔/视口中心）、无任何持久化。

## 修复

- **仓储**：`NoteRepository` 增 `saveZoomViewSourceRect`/`saveZoomViewShown`
  ——`getViewState`→改单字段→`saveViewState` 全量回写（沿用 Phase 1392
  `saveLastCodeBlockLanguage` 模式，保留列不丢）。
- **持久化落点**：`endZoomWindowDrag`（窗拖/把手 resize/边缘滚动/卸载共用
  出口）+ `zoomStepBack`/`zoomStepForward` + `zoomAutoAdvance`（仅真前进）+
  `zoomReturnToInk`（仅真回位）；序列化 `"l,t,r,b"`（`ten.r` 等价）。
- **恢复**：`initZoomSourceRect` 优先恢复持久化位（`restoredZoomSourceRect`
  内存镜像，持久化即同步→会话内隐/显、切页均回原位，对应 `kdk.A` mask62
  保留语义）；非法串经 `parseZoomSourceRect` 校验回落原锚定（`ten.y` 回落
  `sbe.e` 等价）。
- **显隐**：面板 `onAppear`→shown=true；`onDisAppear`→按当时
  `currentTool===ZOOM` 写回——换工具/Close 记 false、整页导航离开保持
  true。`loadNoteData` 载入 shown=true 且当前非 ZOOM → `selectTool(ZOOM)`
  重挂面板（原版 isShown 冷启动恢复等价）。

## 行为差异（相对 Harmony 旧行为）

- 挂载锚定策略由「恒锚末笔」改为「有持久化位→恢复原位，无→末笔/视口
  中心回落」——对应原版 ZoomViewState 会话内保留 sourceRect。
- `zoomViewShown` 恢复会冷启动激活 ZOOM 工具（原版浮窗显隐在 Harmony
  工具门控模型下的等价物）。
- 仅恢复 l,t；宽高随当前 magnification 重算（`ca3:519` 无 magnif 列，
  原版同不持久化）。

## 改动文件

- `note/src/main/ets/data/RepositoryInterfaces.ets` — 两签名
- `note/src/main/ets/data/NoteRepositoryImpl.ets` — `saveZoomViewSourceRect`/
  `saveZoomViewShown`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets` — 载入种子、
  `parseZoomSourceRect`、`persistZoomViewSourceRect`/`persistZoomViewShown`、
  `initZoomSourceRect` 恢复分支、5 处持久化落点、面板 onAppear/onDisAppear
  显隐写回、冷启动 shown 恢复
- `docs/migration/replays/d02-original-zoom-view-state-persist.mjs`（新增）

## 验收

- 硬证据：`wmb.java:75/102`、`ymb.java:61/330`、`ws3.java:295`、
  `kck.java`/`rck.java:19`、`kdk.java:46-54`、`ten.java:103/118`、
  `ca3.java:519`。
- `d02-original-zoom-view-state-persist` 20 检查绿；全量基线全绿。
- `note@default`/`note@ohosTest` HAP 构建成功，无新增 ArkTS 错误。

## fail-closed / 边界

`magnification`/`dockEdge`/`panelInTopHalf` 原版不持久化（无列）→ Harmony
同保持会话内。`isTextOnly` 文本视图模式仍留独立 Phase（渲染管线）。
