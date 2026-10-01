# Phase 1426：SHAPE 描边 nib 误判纠错报告（px5.a 均匀宽 = 既有实现对等）

- 日期：2026-10-01
- 状态：完成（纠错阶段，零代码改动；Desktop Replay 9 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1426-shape-outline-uniform-stroke.md`
- 修正：`docs/migration/adr/ADR-1361-shape-strip-kind-picker.md` 渲染边界节
- Replay：`docs/migration/replays/d02-original-shape-outline-uniform-stroke.mjs`

## 目标

复核 ADR-1361 登记的"SHAPE 描边凿尖几何未接入"待办——该判断基于
`sri.f`/`aj1` 属于 SHAPE 的误读（实则为 CALLIGRAPHY 状态）。

## 纠错结论：无缺口

- `psi`（SHAPE 状态）无 `aj1` 字段；`cc3.H()` 中 `eti.T`（SHAPE）的
  默认 `zsi.h` 恒 null；元素持久化 nib 三列对图形恒 NULL。
- `lnc.u()` 因此恒走 `px5.a` → `k9m.b()` 的 `jmc.c` 均匀宽路径；
  `ox5`/`jmc.b` 凿尖支只对 CALLIGRAPHY 来源元素可达。
- Harmony `strokeShape`（固定 `setLineWidth` + round cap/join +
  DASH/DOTS）即 `px5.a` 语义的精确对等。

## 已更正文书

- ADR-1361「已知渲染差异」改写为「渲染边界：经复核无缺口」并附完整证据链。
- `phase-1425-shape-strip-kind-picker.md`「剩余边界」同步更正。
- 三份跟踪文档 Phase 1425 条目的"待办"措辞改为"经 Phase 1426 复核无缺口"。

## 验证

- `d02-original-shape-outline-uniform-stroke.mjs`：9/9 通过——钉住
  均匀宽描边、无 nib 渲染、nib 状态/写路径 CALLIGRAPHY-only、
  SHAPE 条无 ij1 面板、纠错文书已落地。
- 全量基线与双构建结果见提交说明。
