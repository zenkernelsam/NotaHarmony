# ADR-0549: 原版箭头检测不可恢复 — fail-closed

## Status

Accepted, 2026-09-28.

## Context

原版形状识别链 `e5d` 的第四个候选 `y90(0).c()` 是箭头识别器（见证据
`original-arrow-detection-decode-2026-09-28.md`）：

- 转向角 ≥ π/2 的连续区段各取最大角点作候选拐角；
- 拐角处拆分笔画：前段送 `cg7` 要求得到 LINE，后段送 `br9`（两个
  镜像 `ba0` 翼识别器）；
- 合并置信度 `0.5·shaft + 0.5·head'`（头部 >0.5 即按 1.0 计）；
- 输出 `t06` + `s16.J`（ARROW）。

阻塞点：翼评分器 `ba0.b()`（1.0.3）与其 1.0.1 对应 `e90.b()` 在两份
JADX 反编译中均抛出 `UnsupportedOperationException`，仓库内亦无
smali/dex 文本导出可交叉恢复。翼评分公式与阈值不可获知。

## Decision

- 本地箭头检测 **不移植**：`ShapeDetector` 永不产生
  `ShapeArrowHead.SINGLE`。不发明未经证据支持的拐角/翼启发式。
- 保留并钉死已逐字对齐的三条腿：
  1. 渲染：`ShapeGeometry.lineRenderGeometry`（`l96.W`/`d1j`，
     箭长 `c(w)·46`、半展 `c(w)·20`、轴裁剪、开口 V）。
  2. 入站/出站 op 解码编码（`OriginalShapeGroupOperation` /
     `OriginalCreateShapePayloadEncoder` 偏移 36）。
  3. 部分擦除将箭头 V UNION 进擦除外轮廓
     （`OriginalShapePartialEraser`）。
- `.note` 解析维持 `arrowHead: NONE`：plist 箭头键名无静态证据，
  不臆造键。

## Consequences

- 用户手绘"线+箭头"不再自动变成箭头（原版会在 hold-to-detect 时
  识别）。凡通过同步 op / 未来解析扩展进入的 SINGLE 线仍按原版
  渲染、擦除、回传。
- 若后续获得 `ba0.b()` 字节码（如 dex2jar/其他工具链），本 ADR 标记
  superseded 后可按解码公式补全检测腿。
- 回放 `d02-original-arrow-detection-failclosed.mjs` 钉死该契约：
  检测端无 SINGLE 产出，其余三腿齐备。
