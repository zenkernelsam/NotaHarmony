# Phase 1366 — 库 FAB chip 的 `wp8` 变体（FILLED 主操作）

## 原版证据（`defpackage/cd.java` + `wp8.java`）

`cd` case 0 各项传入不同 `wp8` 按钮变体：
- Import/Templates/DocScan → `wp8.J`（**TINTED**，色调/次级）
- Create Note → `wp8.I`（**FILLED**，填充强调，末位主操作）

`wp8.java` 枚举：`I=FILLED, J=TINTED, K=STROKE, L=PLAIN`。FILLED 即
accent 填充背景 + onAccent 内容色（`cwi.b` 内 icon 按内容色着色 → 浅描边图标）。

## 差距

Harmony `CreateActionChip` 全部 `surface` 背景 + `textPrimary` 文字，无主次区分。

## 修正

- `CreateActionChip` 加 `emphasized: boolean`：FILLED 时 `backgroundColor=accent`、
  label `onAccent`；TINTED 时保持 `surface`/`textPrimary`。
- Create Note chip 传 `emphasized=true` + 白描边 `fab_createnote_filled.svg`
  （onAccent 双主题均 `#FFFFFF`，无需 dark 限定符）。其余 chip 仍为 TINTED。

## 验证

`d02-library-fab-order.mjs` 断言 `fab_createnote_filled ... , true)`：25/25。
