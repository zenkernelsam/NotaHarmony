# ADR-0889 — 写↔读对称首证

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `haj.c` = ln2 写器：f0-f3 序与读端
  c(4)/c(6)/c(8)/c(10) 逐项镜像——`4+2i`
  公式两侧闭环。
- `nti.X` = cxc 12B 内联写器：逆序写入
  index@8/timestamp@4/pad@2/site@0——与 880
  读端布局逐字节一致。

## Harmony 决策

写器字段序必须与读器 c(4+2i) 镜像；
禁止凭写器推断额外字段（见 922 教训）。

## Parity 状态

等价（byte-exact）。

## 验证

- `d02-write-side-symmetry.mjs`：9/9 通过。
- 全量 Replay 818 文件绿，见 Phase 945 提交。
