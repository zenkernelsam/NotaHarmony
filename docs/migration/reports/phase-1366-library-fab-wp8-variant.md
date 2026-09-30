# Phase 1366 — 库 FAB chip `wp8` 变体（FILLED 主操作）

## 摘要

原版 `cd` case 0 中 Create Note 用 `wp8.I`=**FILLED**（accent 填充+onAccent
内容色）作末位主操作，其余 Import/Templates/DocScan 用 `wp8.J`=TINTED。
Harmony 此前一律 `surface`。本阶段为 `CreateActionChip` 加 `emphasized`：
FILLED 用 `accent` 底+`onAccent` 字+白描边 `fab_createnote_filled.svg`；
其余保持 TINTED。

## 改动

- `note/.../LibraryPage.ets`：`CreateActionChip` 加 `emphasized` 形参。
- `note/.../resources/base/media/fab_createnote_filled.svg`（白描边，新增）。
- `docs/migration/replays/d02-library-fab-order.mjs`：25/25。
