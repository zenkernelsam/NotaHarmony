# ADR-0864 — setter 包装布局 + v01/枚举实名

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- setter 统一 `{value@c(4)}` 单槽：z1d SetBool、
  z2d SetString、k2d SetFloat、y2d SetSize、
  g2d SetColor、m2d SetPageBackground——三路态
  （缺席=不改）。
- `v01` = Boundary 内联结构 `{cxc@0, y01@12}`；
  y01 = BoundaryType{BEFORE,AFTER,START_OF_DOC,
  END_OF_DOC}——文本范围=位置 ID+边界方向复合锚。
- `tv6` = LayoutMode{PAGED,PAGELESS}；
  `dz0` = BlockWrapSupport{WRAP_ENABLED,
  WRAP_DISABLED,LEGACY_WRAP_ENABLED}（迁移值）。

## Harmony 决策

setter 三路态语义对齐；Boundary 复合锚与枚举全集
（含 LEGACY_WRAP_ENABLED）对齐。

## Parity 状态

等价（setter 层全闭）。

## 验证

- `d02-setter-enums.mjs`：12/12 通过。
- 全量 Replay 793 文件绿，见 Phase 920 提交。
