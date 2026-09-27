# ADR-0874 — 形状定义多态全链

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `z4d` = ShapeDefKind{NONE=0,LINE=1,POLYGON=2,
  NORMAL_SHAPE=3}；`z5c.a0` 工厂按序数造
  `uf7`/`pra`/`oz8`；`v(ao2)`/`w(le8)` 读判别子+
  子表两字段。
- 定义表：uf7=Line{start,cp1,cp2,end:fqa,arrowHead}、
  pra=Polygon{points}、oz8=NormalShape{type,size}。
- `z5c.Z(cxc)` = "{site},{ts},{idx}" 字符串化。

## Harmony 决策

形状定义分发对齐：判别子+子表+三定义表模型。

## Parity 状态

等价（多态链闭合）。

## 验证

- `d02-shape-defs.mjs`：8/8 通过。
- 全量 Replay 803 文件绿，见 Phase 930 提交。
