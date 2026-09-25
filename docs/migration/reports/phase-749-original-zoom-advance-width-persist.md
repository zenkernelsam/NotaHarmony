# Phase 749：原版 Zoom 自动前进区宽持久化（o59.r）

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-749-original-zoom-advance-width-persist.md`
> ADR：`docs/migration/adr/ADR-0697-original-zoom-advance-width-persist.md`
> Replay：`docs/migration/replays/d02-original-zoom-view.mjs`（82 pins，全绿）

## 背景

Phase 747 移植的 Zoom 面板把自动前进区宽放在 `NoteCanvasView` 内存
`@State`，每次编辑器挂载回退 180vp。复核 `o59.java`/`n27.java`/`bc7.java`
发现原版该值是 **Preferences DataStore 持久化设置**——用户拖拽调整一次后
跨会话保留。

## 原版证据（decompiled_1.0.3）

- `o59.java:23`：`eua r = new eua("zoomViewAdvanceRegionWidthDp")`——
  DataStore 键对象，与 hideNavigationBar 等编辑器设置同组；
- `g0j.java:250`：advance_tab 拖拽回调绑定 `ahg.setAdvanceRegionWidth(F)V`；
- `n27.java:42`：`tk8.g(o59.r, Float.valueOf(f))`——逐次写库；
- `bc7.java:211`：`tk8.f(o59.r)` 随编辑器设置读回；
- `ggg.e`/`lgg` 默认 `180.0f`。

## 移植内容

| 模块 | 变更 |
|------|------|
| `data/EditorSettingsStore.ets` | 新增同名键 `zoomViewAdvanceRegionWidthDp` + `DEFAULT_ZOOM_ADVANCE_WIDTH_DP=180` + 通用 number get/save（mutex + flush 失败回滚范式）；接口加 `get/saveZoomAdvanceWidthDp` |
| `ui/editor/EditorViewModel.ets` | `zoomAdvanceWidthDp` 字段随设置块加载；`setZoomAdvanceWidthDp` 走 `enqueueSave` 乐观写 + 失败回滚 |
| `ui/editor/NoteCanvasView.ets` | `initZoomSourceRect` 挂载同步 VM 值；`onAdvanceRegionCommit` 拖拽提交点持久化 + 失败回滚本地 @State |
| `ui/editor/NoteZoomView.ets` | advance_tab `PanGesture` 补 `onActionStart`/`onActionEnd` |
| `test/EditorViewModel.test.ets` | FakeEditorSettingsRepository 同步接口扩展 |

## 顺带修复

拖拽基准宽原实现逐帧以 `advanceWidthVp - offsetX` 计算——`offsetX` 是
自手势起点的累计量，而 `advanceWidthVp` prop 每帧已被刷新，导致拖宽
漂移（越走越快）。改为 `onActionStart` 钉住起点宽后再减累计量。

## 差异登记（详见 ADR-0697）

原版 `setAdvanceRegionWidth` 逐帧写 DataStore；Harmony 在 `onActionEnd`
提交点写一次——跨会话可观察语义等价（下次挂载读回上次终值），拖动过程
不落盘。

## 验证

- 专项 `d02-original-zoom-view.mjs` 82/82；
- 全量 Desktop Replay 见提交；
- `note@default` / `note@ohosTest` 双 HAP 构建成功。
