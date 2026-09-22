# Phase 578 — 原版箭头识别解码与 fail-closed（2026-09-28）

## 目标

审计注册表遗留项：原版形状识别链第四个候选 `y90(0).c()`（箭头检测）
的完整解码，判断能否移植。

## 原版证据（decompiled_1.0.3/sources/defpackage）

- `y90.c()`：转向角 ≥ π/2 区段取最大角点 → 拐角拆分 → 前段 `cg7`
  要求 LINE，后段 `br9`（两个镜像 `ba0` 翼识别器）→ 置信度
  `0.5·shaft + 0.5·head'`（head >0.5 按 1.0 计）→ `t06` + `s16.J`
  = ARROW。
- `ba0.b()`（1.0.3）与 `e90.b()`（1.0.1 对应）在两份 JADX 输出中
  均未反编译（`UnsupportedOperationException`），仓库无 smali/dex
  文本导出 —— 翼评分公式不可恢复。

## 决策（ADR-0549）

本地箭头检测 fail-closed：`ShapeDetector` 永不产出 SINGLE；不发明
未经证据支持的启发式。同时钉死已对齐的三条腿：

1. 渲染 `lineRenderGeometry`/`originalShapeArrowScale`（`l96.W`/`d1j`
   逐字：`c(w)·46` 箭长、`c(w)·20` 半展、轴裁剪、开口 V）。
2. 入站/出站 op 解码编码（偏移 36，`arrowHead===1→SINGLE`）。
3. 部分擦除 UNION 箭头 V。

`.note` 解析维持 NONE —— plist 箭头键名无静态证据。

## 验证

- 专项 fixture `d02-original-arrow-detection-failclosed.mjs`：13/13。
- 无源码改动（纯审计 + 文档 + fixture 钉死现有契约）。

## 遗留

若后续以其他工具链（dex2jar 等）恢复 `ba0.b()` 字节码，可按公式
补全检测腿并 supersede ADR-0549。
