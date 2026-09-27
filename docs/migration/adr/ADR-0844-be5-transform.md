# ADR-0844 — `be5` 变换契约 + `y18` 矩阵助手

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `be5` = 可变换元素接口：{bounds:k11, scale:qed,
  kind:v09, origin:fqa, page:cxc, rotation:Float} +
  `P(fqa)` = **T·R·S** 变换管线（平移→度旋转→缩放）。
- `y18` = 4×4 列主序矩阵助手：a=I、l=平移、h=旋转
  （弧度）、i=缩放、d=矩形变换、b=逆族。
- `qsa extends be5` + `d(uq9,ie8)` = ModifyPosition
  应用槽；op 字段 = P() 输入直映。

## Harmony 决策

元素变换按 T·R·S 序、度单位旋转、4×4 列主序对齐。

## Parity 状态

等价（op→几何语义闭合）。

## 验证

- `d02-be5-transform.mjs`：14/14 通过。
- 全量 Replay 773 文件绿，见 Phase 900 提交。
