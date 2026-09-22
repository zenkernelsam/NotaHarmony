# Phase 591 — 原版选区 DESELECT = deselectMode（点按移除模式）

- 日期：2026-09-28
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-deselect-mode-2026-09-28.md`
- ADR：`docs/migration/adr/ADR-0560-original-deselect-mode.md`
- Replay：`docs/migration/replays/d02-original-deselect-mode.mjs`（22 项断言）

## 背景

Phase 590 解码 `dl1` case2 选区手势分发时发现 `ftc.h=true` 的
deselectMode 分支（`stc`/`qtc`/`utc`）。Phase 591 继续追
`dhb` case20 → `dsc.DESELECT`：原版选区菜单的 "Deselect"
项（`circle_minus` 图标）不是"退出选区"，而是**进入点按移除模式**。
Harmony 迁移层此前把 DESELECT 错映射为"Done/清空选区"。

## 原版语义（decompiled_1.0.3）

- `dhb.java` case20：`fvb.n` 保存进入前 `ftc` 快照，
  `ftc.h(deselectMode)=true`。
- `dl1.java` case2 `h=true` 分支：
  - 点中选中元素 → `stc`（`ej9` case18：选中集 −id、deselectedIds +id）；
  - 点中组（`cqc`）→ 整组 `stc`；
  - 覆盖层内非元素 → `utc` 消费无动作；
  - 覆盖层外 → `qtc` → `z39` case17 **取消模式并恢复 `fvb.n` 快照**。
- `n6d`/`k2f`：模式有 `onConfirmDeselectMode`/`onCancelDeselectMode`
  回调对（确认保留缩减、取消恢复快照）。
- 选中集清空 → `fvb.a()` 退出选区。

## Harmony 实现

- `SelectionTool`：`SelectionState.deselectMode`/`deselectedIds` +
  `preDeselectSelection` 快照；`enterDeselectMode` /
  `deselectElements(entityIds, groupIds)` / `confirmDeselectMode` /
  `cancelDeselectMode`；普通选区生命周期方法同步复位。
- `SelectionOverlay`：`@Prop deselectMode`；模式内 ⋯ 菜单只渲染
  Done(confirm)/Cancel；普通模式末项标签改为 `deselect`（新增
  base/zh_CN 字符串，对齐 `selection_menu_deselect`）。
- `NoteCanvasView`：`@State selectionDeselectMode` 镜像；
  `onSelectionMenuAction` 路由 DESELECT→enter、DESELECT_CONFIRM→
  confirm、DESELECT_CANCEL→cancel；`isSelectionActive` 分支头部加
  deselectMode pointer-down 分流（命中→`deselectElements`，覆盖层内
  miss→消费，覆盖层外→cancel 恢复）；新增 `deselectTargetIdsAt`
  命中测试（topmost 命中必须 ∈ 选中集；组命中经
  `resolveOriginalSelectedGroupLeaves` 整组展开）。

## 偏差

见 ADR-0560 §偏差：确认/取消承载于 ⋯ 菜单（语义等价）；`ntc` 动态
组未选中成员命中路径静态不可达；键盘快捷键入口未移植。

## 验证

- `node docs/migration/replays/d02-original-deselect-mode.mjs` → 22/22。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
