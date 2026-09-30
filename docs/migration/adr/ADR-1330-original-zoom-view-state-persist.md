# ADR-1330 — 放大窗 `zoomViewSourceRect`/`zoomViewShown` 持久化与恢复

- 状态：已接受
- 日期：2026-08（Phase 1394）
- 证据：`docs/migration/evidence/phase-1394-original-zoom-view-state-persist.md`
- 修订：ADR-1329 对 zoomView* 列「仅保列、不强切恢复语义」的暂决——
  本 Phase 完成行为接入。

## 决策

接入原版按笔记持久化放大窗状态的行为（`wmb.java:75/102` 专属 UPDATE、
`ws3.java:295` 单读恢复、`kck`/`kdk.A mask62` 会话内保留 sourceRect）：

1. **仓储**：`NoteRepository` 增 `saveZoomViewSourceRect`/`saveZoomViewShown`，
   走 `getViewState`→改单字段→`saveViewState`（全量回写，保留列不丢）。
2. **持久化落点**：窗口拖动/把手 resize/边缘滚动共用 `endZoomWindowDrag`
   出口；`zoomStepBack`/`Forward`、真前进的 `zoomAutoAdvance`、真回位的
   `zoomReturnToInk` 各自落点。序列化 `"l,t,r,b"`（`ten.r` 等价）。
3. **恢复**：`initZoomSourceRect` 优先恢复持久化位（内存镜像
   `restoredZoomSourceRect`，持久化即同步）；`zoomViewShown=true` 冷启动
   → `selectTool(ZOOM)` 重挂面板。
4. **显隐写回**：面板 `onAppear`→true；`onDisAppear`→按当时
   `currentTool===ZOOM` 写——换工具/Close 记 false，整页导航离开保持
   true（等价原版 isShown 随关笔记保留）。

## 行为差异（相对 Harmony 旧行为）

- 原 `initZoomSourceRect` 每次挂载锚定末笔续写位；现「有持久化位→恢复
  原位」。依据 `kdk.A()` mask62：原版隐窗保留 sourceRect，续用旧位是
  原版语义——切页/重开面板不再跳位。
- `zoomViewShown` 恢复会把冷启动工具切到 ZOOM：原版 magnifier 是独立
  浮窗显隐，Harmony 模型下 ZOOM 工具激活即等价显隐。
- 仅恢复 l,t；宽高随当前 magnification 重算（原版亦不在 note_state 存
  magnif——`ca3:519` 无列）。

## 回归

`d02-original-zoom-view-state-persist.mjs`（20 检查）。fixture 引用见
本 ADR 与 evidence 文档（满足一致性检查）。
