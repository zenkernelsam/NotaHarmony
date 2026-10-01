# Phase 1441 — 选择菜单实体专属行 lsf 门控 + 已锁单元素单行菜单

## 范围

Phase 1440 对齐 `urf` 行序时发现：`hv6VarP1` 仅由 `lsf`（单元素点选）
推导，故 `CROP`/`EDIT_MATH`/`FLIP_H`/`FLIP_V` 全部 lsf 专属；且旗开 +
点选已锁单元素时菜单仅 `UNLOCK` 一行。Harmony 原按基数开放三门、
无单行已锁菜单。

## 原版证据

- `urf.java:243+`：`hv6VarP1 = zq.p0(r0b, lsfVar2.a, 6)`，`lsfVar2 =
  msfVar instanceof lsf ? …`——非 lsf 恒 null。
- `CROP`：`hv6VarP1 instanceof l97`；`EDIT_MATH`：`instanceof cv9`；
  `FLIP_H/V`：同 `z6`（单图 l97）。
- z 支：`h45.b(h35.I)`（POSITION_LOCKED 旗）+ `lsf` + `cjm.h`（实体已锁）
  → `xqf(oag.x2(wqf.Y), ∅)` = 仅 UNLOCK。

## Harmony 变更

- `NoteCanvasView.ets`：三门 `!supportsDeselectMode` 前置；
  `canFlipImageSelection` 收紧 `imageIds.length === 1`；
  新增 `selectionLockedOnly` 镜像（非 isf + 无组 + 恰一可锁已锁实体）。
- `SelectionOverlay.ets`：`@Prop lockedOnly`；装配前段 `lockedOnly`
  → 仅 `UNLOCK` 早退。

## 验证

- `d02-selection-entity-rows-lsf-gate.mjs`：15/15。
- 全量基线与双构建结果见提交记录（下文验收节）。

## 验收

- 原版证据：见 `docs/migration/evidence/phase-1441-selection-entity-rows-lsf-gate.md`。
- 决策：`ADR-1376`。
- 基线：见提交信息。
- 构建：`note@default` / `note@ohosTest`。
