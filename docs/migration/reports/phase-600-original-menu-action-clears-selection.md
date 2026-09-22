# Phase 600 — 选区菜单动作完成后清空选区（dhb → fvbVar.a() 终态）

- 日期：2026-09-23
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-menu-action-clears-selection-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0569-original-menu-action-clears-selection.md`
- Replay：`docs/migration/replays/d02-original-menu-action-clears-selection.mjs`（18 项断言）

## 背景

原版 `dhb` 选区菜单分发的成功终态：`fvbVar.a()` 清选区——
COPY/CUT/DUPLICATE/GROUP/UNGROUP/DELETE/FLIP/LOCK/UNLOCK；
DUPLICATE 由 `lg2.e` 重选粘贴副本。STYLE/SEND_*/EDIT_MATH/
CROP/DESELECT/MORE 保留。

Harmony 原实现五处相反：COPY 保留、GROUP/UNGROUP 重选成员/
新组、FLIP/LOCK 保留。

## 实现

- COPY：成功提交剪贴板 → `clearSelectionWithRegisterReset()`。
- GROUP/UNGROUP：成功分支去掉 `selectElementIds` 重选 → 清空；
  顺带移除 UNGROUP 中失效的 id 局部变量。
- FLIP_H/V：尾部 `updateSelectionOverlay` → 清空。
- LOCK/UNLOCK：尾部同上。
- DUPLICATE 不动（粘贴路径 `selectElementIds` 已等价重选）。

## 偏差

见 ADR-0569 §偏差：寄存器重置并入清空等价终态；组后需重新
点选为原版语义；菜单随覆盖层同步消失。

## 验证

- `node docs/migration/replays/d02-original-menu-action-clears-selection.mjs` → 18/18。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
