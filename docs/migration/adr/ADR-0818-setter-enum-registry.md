# ADR-0818 — setter 包装族 + op 枚举登记

## 状态

accepted（文档+fixture，无源改动；Harmony 解码/写手已等价）

## 原版契约（`decompiled_1.0.3`）

- 六枚单字段 setter 包装：k2d{Float}、y2d{qed}、z2d{String}、
  g2d{hu1}、p2d{bmb}、n2d{k3a} —— 字段存在=改、缺省=不改，
  供所有 MODIFY_* payload 复用。
- 枚举：u16 线层工具（PEN/PENCIL/HIGHLIGHTER/TAPE/
  WHOLE_ERASER/PARTIAL_ERASER/SELECTION/LASER）、t16 墨迹样式
  （VARIABLE_WIDTH/FIXED_WIDTH/DASH/DOTS）、ife 形状填充 ×9、
  z4d 形状种类、ty0 块角、ive 标志、im 批注锚。

## Harmony 决策

- u16 线值由 `readUint8` 逐值解码（tape=3、pencil=1、
  highlighter=2、partialEraser=5），可创建墨迹门限排除
  eraser/selection/laser；`BrushTypes` 为 UI 层 `a6f` 枚举、
  与线值分离（已在 BrushTypes 注释标注 `a6f.R`）。
- setter「存在即改」语义由各 Modify*Encoder 的
  `update.X === null ? 0 : offset` null-gate 表达。

## Parity 状态

等价。

## 验证

- `d02-setter-enum-registry.mjs`：53/53 通过。
- 全量 Replay 与双 HAP 构建见 Phase 874 提交。
