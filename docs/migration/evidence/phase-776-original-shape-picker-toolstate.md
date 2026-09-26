# 原版 1.4.2 形状工具选择器与工具状态列增量登记（Phase 776 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/resources/res/values/strings.xml`、
>   `defpackage/{zmb,ca3,e83,r5g,ro7,kj(1.0.3)}.java`
> 性质：1.4.2 版本差证据登记；无 Harmony 代码变更。

## 一、显式形状工具（1.4.2 新增 UI）

1.0.3 仅有 hold-to-detect（画后长按识别）；1.4.2 新增**先选形状再画**
的显式工具：

```text
ui_tools__shape           = "Shape"
ui_tools__shape_rectangle = "Rectangle"
ui_tools__shape_ellipse   = "Ellipse"
ui_tools__shape_triangle  = "Triangle"
ui_tools__shape_diamond   = "Diamond"
ui_tools__shape_line      = "Line"
ui_tools__shape_arrow     = "Arrow"
```

（1.0.3 strings.xml 无 `ui_tools__shape_*` 族；`kj.java` 的
`CreateShape(shapeKind=..., smartHighlight=false, ...)` 证明 1.0.3
识别管线已带 shapeKind 参数，但无显式选择 UI。）

## 二、`ToolStateEntity` 三列增量（Phase 767 细化）

| 列 | 语义 |
|---|---|
| `shapeKind` TEXT DEFAULT 'RECTANGLE' | 形状工具当前种类持久化（跨会话记忆） |
| `googleInkBrushPackId` INTEGER DEFAULT NULL | 笔工具绑定的 Google Ink/.brushpack 包 id（Phase 762 笔刷包体系） |
| `penLastStandardColorWellIndex` INTEGER DEFAULT NULL | 每笔记住最后选中的标准色井位 |

另有迁移期细化列：`selectionIsFreehand`、`eraserIsPartial`、
`tapePattern`、外键 `tray_owner_id → TrayEntity(tray_id)
ON DELETE CASCADE`（`ToolStateEntity_new` 重建迁移，Phase 767）。

## 三、Harmony 现状

- Harmony 有 `ShapeDetector`/`ShapeRecognition`/`ShapeGeometry`
  （hold-to-detect 路径，1.0.3 对齐）；**无显式形状选择器**。
- 工具状态持久化无 shapeKind/brushPackId/colorWellIndex 对应列。

## 四、分类

| 项 | 分类 |
|---|---|
| 显式形状选择器 + shapeKind 持久化 | 版本差·本地候选（纯本地 UX/持久化，可移植——但 1.0.3 基线无此功能，回移待判定） |
| googleInkBrushPackId | 依赖 .brushpack 引擎簇（Phase 762），随簇处置 |
| penLastStandardColorWellIndex | 本地可移植（色井记忆） |
