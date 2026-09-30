# ADR-0657 — 库创建 FAB 速拨图标（`cwi.b` icon+label）

## 状态

已接受（Phase 1365）。

## 背景

原版库创建 FAB 每项 chip（`cwi.b`）渲染 **图标 painter + 标签**，图标资源为
`feature_library__importnewnote`/`templatenewnote`/`createnote`、
`ui_fileimport__docscan`（24dp stroke 矢量，`stroke=#171a20`/`#000000`、
`strokeWidth≈1.25`、round caps）。Harmony `CreateActionChip` 此前仅 `Text`。

## 决定

1. `CreateActionChip` 增加 `icon` 形参，渲染 `Row { Image(icon,18) + Text }`，
   与 `cwi.b`（`go5.b` 图标 + `tpe.b` 标签）结构对齐。
2. 四个 drawable 的 `pathData`/stroke 逐字节移植为 `base/media/fab_*.svg`。
3. 暗色变体放 `resources/dark/media/fab_*.svg`（stroke→`#E6E6E6` = 暗
   textPrimary），经 `dark` 限定符自动换肤——对齐原版 `iu1` 内容色着色语义。
4. Record chip（ADR-0655 等价项，cd 本无）复用现成 `shortcut_new_recording` 图标。

## 后果

FAB 速拨项现为图标+文字，与原版视觉结构一致；暗色模式下图标正确取
`#E6E6E6`。

## 验证

`d02-library-fab-order.mjs`：24/24。
