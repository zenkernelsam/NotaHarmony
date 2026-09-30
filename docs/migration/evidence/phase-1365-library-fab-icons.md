# Phase 1365 — 库创建 FAB 速拨图标保真（`cwi.b` icon+label）

## 原版证据（`defpackage/cd.java` case 0 → `cwi.b`）

`cd` case 0 每项调用 `cwi.b(modifier, label, iconRes, wp8Variant, …)`：

| 项 | label key | icon drawable |
|----|-----------|---------------|
| Import | `feature_library__import` | `feature_library__importnewnote` |
| Templates | `feature_library__templates` | `feature_library__templatenewnote` |
| DocScan | `feature_library__docscan` | `ui_fileimport__docscan` |
| Create Note | `feature_library__create_note` | `feature_library__createnote` |

`cwi.b` 体内：`go5.b(rh8.K(i))` 渲染图标 painter，`tpe.b(str)` 渲染标签——
即 **图标+文字** chip。四个 drawable 均为 24dp stroke 矢量
（`fill=none`/`stroke=#171a20`或`#000000`/`strokeWidth≈1.25`/round caps）。

## 差距

Harmony `CreateActionChip` 仅渲染 `Text`，无图标。

## 修正

- 生成 4 个 SVG 于 `resources/base/media/`：`fab_import/fab_templates/
  fab_docscan/fab_createnote`，pathData/stroke 逐字节来自原版 drawable。
- 生成暗色变体于 `resources/dark/media/`（stroke→`#E6E6E6`，对应
  `EditorTheme` 暗 textPrimary），借 `dark` 资源限定符自动换肤。
- `CreateActionChip` 改为 `Row { Image(icon).18 + Text }`，签名加 `icon`；
  各 chip 传入对应 fab_* 矢量；Record chip 用现成 `shortcut_new_recording`。

## 验证

`d02-library-fab-order.mjs` 扩展至 24/24（图标接线 + media/dark 双存在）。
