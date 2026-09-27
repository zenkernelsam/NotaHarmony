# ADR-0852 — `ln2`/`nz9`/`k3a` 读侧 accessor 图 + 读写对称闭合

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `ln2` 读图：location:cxc@4、background:nz9@6、
  pageCount@8、bookmark:oz9@10——与 haj.a 写序对称。
- `nz9` 读图：paper:k3a@4、pdfLayout:sw9@6、rotation@8、
  size:qed@10、margins:vy7@12——与 vv7.L 写序对称。
- `k3a` 读图：template:n3a@4、float@6、bool@8/10、
  color:hu1@12、enum:cmf@14——与 fag.o0 写序对称。
- **读写对称闭合**：c(4+2i) 读槽 = C(N) 内写槽逐对。

## Harmony 决策

三表解码槽位对齐；getter-字段名映射建立。

## Parity 状态

等价（页面子树读写双向闭合）。

## 验证

- `d02-page-reader-maps.mjs`：18/18 通过。
- 全量 Replay 781 文件绿，见 Phase 908 提交。
