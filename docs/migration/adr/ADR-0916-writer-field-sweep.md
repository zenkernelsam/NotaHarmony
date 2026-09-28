# ADR-0916 — 全表写器字段数/required 槽总稽查

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

对 z0c 注册表全部 41 个 cee 表写器逐一抽 `C(N)` +
`z(iN,slot)`，得写侧字段宽表（见证据）。要点：

- **required 是不对称契约**：e46/ln2/mqf/yda/sdf/
  nz9/k3a/sw9/my3 等写侧零 required——required 本质是
  读侧校验；写侧只对身份键/锚点/成员置 z()。
- `ys2.O` = dm2 平铺 19 参工厂签名，C(20)、
  required f0+f1+f7。
- `v0j.d` 在写 he8 时先建 `C(1)+c(0,bcg.I,0)` 内嵌
  b3d 表——Phase 949 "b3d 缺席注册表"实证闭环。
- le8/td8 f0 required（shape/blocks）；rl2 三连
  required {page,origin,size}。

## Harmony 决策

写侧 required 表 = Harmony encode 校验清单；与读侧
校验不对称属原版设计，不补不改。

## Parity 状态

等价。

## 验证

- `d02-writer-field-sweep.mjs`：46/46 通过。
