# ADR-0560 — 原版选区 DESELECT = deselectMode（点按移除模式）

- 状态：Accepted
- Phase 591；对齐 `dsc.DESELECT`/`dhb` case20/`dl1` case2/`ej9` case18/
  `z39` case17/`n6d`/`k2f`/`fvb.n`（decompiled_1.0.3）。

## 背景

迁移前 `SelectionMenuAction.DESELECT` 被映射为"完成/退出选区"（清
空选区）。原版解码表明 DESELECT 是完全不同的语义：进入一个**点按
移除模式**——

- 进入时把当前 `ftc` 存入 `fvb.n`（取消时恢复的快照）；
- 模式内点按选中元素/组 → 移出选中集并入 `deselectedIds`；
- 覆盖层内非元素命中 → 消费无动作；覆盖层外命中 → 取消整个模式并
  恢复快照；
- 显式确认（保留缩减结果）/取消（恢复进入前快照）退出。

## 决策

- `SelectionState` 增加 `deselectMode`/`deselectedIds`，
  `SelectionTool` 持有 `preDeselectSelection` 六类 id 快照。
- `DESELECT` 菜单项标签从 `done` 改为 `deselect`（新增字符串资源，
  对齐 `selection_menu_deselect`）。
- deselectMode 下 ⋯ 菜单只渲染 Done(confirm)/Cancel 两项，对齐
  `k2f.onConfirmDeselectMode/onCancelDeselectMode` 回调对。
- pointer-down 分流在 `isSelectionActive` 分支头部：模式内命中选中
  元素/组 → `deselectElements`；覆盖层内未命中 → no-op（消费）；
  覆盖层外 → `cancelDeselectMode` 恢复快照。
- 全部选中集为空 → 走 `deselect()` 退出选区（对齐 `g.isEmpty →
  fvb.a()`）。

## 偏差（fail-closed 记录）

1. 确认/取消用 ⋯ 菜单项承载而非原版专用 UI 条——语义等价。
2. `ntc` 动态组"命中未选中成员但组内成员被选中"路径在静态持久组
   模型下不可达，未单独实现。
3. 键盘快捷键入口（`androidDeselectMode`/`kbd_shortcut_dismiss_
   deselect`）未移植——Harmony 版无硬件键盘层。

## 验证

- `docs/migration/replays/d02-original-deselect-mode.mjs` 22 项静态断言。
- 证据：`docs/migration/evidence/original-deselect-mode-2026-09-28.md`。
