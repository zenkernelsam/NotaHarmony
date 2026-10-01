# Phase 1445 报告 — deselectMode 钉住选区界（mud case7 / zf3 / m5b 13-14 精证）

## 目标

完成原版 deselectMode（`isf.h`）点除语义审计：逐成员移除、组剔除、空态消亡、确认/取消快照、以及点除期间选区轮廓的行为。

## 原版取证

- `isf.java`：字段定稿——`a`=选区界（`o=hsm.b(a,f,m)`=可见轮廓+命中域）、`g`=叶子 id 集、`m`/`n`=组集、`i`=已点除累计、`h`=模式位、`j`=会话 UUID。
- `sqf` case21 / `dqd` case16-17：进模式 `h=true` 存 `ome.m` 快照；出模式 `h=false`+`i=∅`。
- `zf3`：仅 `h=true` 产事件；`ssf` 单元素→剔单成员；`rsf` 组命中→`ysf(tof.b, tof.a)` **整组剔**；界内空点 `atf`(None)；界外 `wsf`(CancelDeselectMode)；界判定用 `a`。
- `mud` case7：`g′=g−set6`、`i′=i∪set6`、`m′=n′=m−组`、`a/b/c/j` 保留；`g′` 空 → `null` → 选区消亡 + `d9c` 弃快照。
- `m5b` case13/14：确认=弃快照+缩减保持；取消=`htd` 回灌（仅同一 `j` 会话且仍 `h` 才恢复）。

## 缺口与修复

**缺口**：Harmony `selectionRect` 恒为存活成员 union——点除时轮廓逐次收缩，界外取消判定域同步变小。原版 `isf.a` 在点除中保留，轮廓钉住。

**修复**：
- `SelectionState.deselectBounds`（入模界钉住，画布坐标）；`enterDeselectMode(bounds)` 接收 `selectionBoundsCanvas()`。
- `updateSelectionOverlay` 尾段：deselectMode 下用钉住界替代成员 union（`pointInSelectionRect` 的界内/界外域随之钉住，对齐 `f5n.h(a,…)`）。
- `deselectElements` 增模式门兜底；`confirm`/`cancel`/`deselect`/`beginSelection`/`selectElementIds` 五路清钉住界。

## 复核一致项（无改动）

整组点除、界内空点/界外取消、确认留缩减/取消回快照、剔空弃快照、`j` 守卫等价（Harmony 快照与模式同生共死，拒恢复支不可达）。

## 验证

- 新 fixture `d02-deselect-mode-pinned-bounds.mjs` 14/14；`d02-original-deselect-mode.mjs`（更新入模签名 pin）22/22；`d02-selection-deselect-isf-gate.mjs` 18/18。
- 全量 Desktop Replay 基线 1295/1295 全绿。
- `note@default` 与 clean `note@ohosTest` 双构建通过。

## 文件

- 改动：`note/src/main/ets/rendering/SelectionTool.ets`、`note/src/main/ets/ui/editor/NoteCanvasView.ets`
- fixture：`docs/migration/replays/d02-deselect-mode-pinned-bounds.mjs`；更新 `d02-original-deselect-mode.mjs`
- 证据：`docs/migration/evidence/phase-1445-deselect-mode-pinned-bounds.md`
- ADR：`docs/migration/adr/ADR-1380-deselect-mode-pinned-bounds.md`
