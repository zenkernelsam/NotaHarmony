# ADR-0589 — 交互标记后 200ms 长按菜单抑制（yqa/g39.b()）

- 状态：Accepted
- Phase 620；对齐 `g39.a()/b()` + `g1f` 打点分派 + `yqa` 门消费点
  （decompiled_1.0.3）。

## 背景

原版 `g39` 维护一个"最近交互"时间戳：`a()` 打点、`b()` 判定
"距今 <200ms"。`g1f` 手势分派在两类事件上打点：

- `ktc` 选区事件为 null/空（`case4`）——选区变空；
- `r5f` 手势面事件（default 分支）——每次面切换都打点。

消费点 `yqa`（空处长按 → PASTE/SELECT_ALL 菜单）：`z=false` 分支
若 `g39.b()` 为真直接 return——**清空选区或切换工具后 200ms 内的
长按不弹菜单**。`ej9` case19 的 `wtc` 拖拽结束通知也受同一窗口
抑制。

Harmony 旧实现：`bindContextMenu(ClipboardPasteContextMenu,
LongPress)` 无任何抑制——清空/切换后立即长按照常弹菜单。

## 决策

1. 标记位：
   - `lastSelectionClearTime`（NoteCanvasView）在
     `clearSelectionWithRegisterReset`（选区清空总漏斗）、页面加载
     deselect、过小区域选区丢弃 deselect 三处打点——覆盖全部
     "选区变空"路径（`g1f` case4 等价）。
   - `toolChangedAt`（EditorViewModel）在 `applyActiveState` 中
     `currentTool` 真正变化时打点（`r5f` 面切换等价；无变化不打点，
     避免激活状态重放误标）。
2. 门：`recentInteractionGateActive()` = 两标记较大者距今 <200ms；
   `ClipboardPasteContextMenu` 门内不产出 `MenuItem`——ArkUI
   `bindContextMenu` 无 veto 钩子，空 `Menu` 不弹层（与既有
   `canPasteClipboardNow()` 条件同手法）。

## 边界

- `ej9` case19 的 `wtc` 拖拽结束通知抑制不可表达——Harmony 无
  `l51`/`v39` 事件总线，拖拽提交的副作用（选区矩形重算、覆盖层
  刷新）是同步内联的，无尾随通知可吞。
- `yqa` 的 `z=true` 分支（触控笔直发）不受门控；Harmony 长按
  不区分笔/指来源——ArkUI `bindContextMenu` 不提供来源信息，
  统一按 `z=false` 门控处理（更严格侧的一致化）。
- 页面加载 deselect 打点会使页面打开后 200ms 内长按无菜单——与
  原版语义一致（选区重置即打点）。
- `u50`/`e39` 协程与 `l51` 总线属于事件管线，未移植。

## 证据

- `docs/migration/evidence/original-recent-interaction-menu-gate-2026-09-28.md`
- `docs/migration/replays/d02-original-recent-interaction-menu-gate.mjs`
  （14/14）
- `g39.java:17-31`；`g1f.java:248-266`；`yqa.java:215-223`；
  `ej9.java:248-254`
