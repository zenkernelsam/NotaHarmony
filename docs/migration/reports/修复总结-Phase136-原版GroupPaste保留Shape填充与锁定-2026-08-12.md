# Phase 136 修复总结：原版 Group Paste 保留 Shape 填充与锁定

## 原版对照与问题

- 原版 `laj.m()` 在同一条 type-18 `CREATE_SHAPE` 中写入 field 11 fillColor 与 field 15
  positionLocked；`n5d` 也将二者作为 Shape 的独立状态保存。
- 原版 `ao2.a()` 规定无填充必须使用 `nil`，不能使用 alpha 为 0 的 Color。
- Harmony encoder 虽然 decoder/reducer 已支持这两个字段，却沿用了 Phase 119 手势识别 Shape 的窄门禁，
  一律拒绝 fill 与 lock。Phase 135 Group Paste 因而无法复制常见的有填充或已锁定 Shape。

## 已完成修复

- 扩展既有 type-18 encoder：field 11 在 offset 56 写原版 Color，field 15 在 offset 80 写锁定 bit，
  root object 扩为 84 字节；未填充和未锁定仍沿用原版字段缺省值。
- fillColor 继续接受项目既有的 signed/unsigned 32-bit ARGB 表示，但 alpha 为 0 时在进入事务前明确拒绝，
  与原版 `ao2` 完全一致。
- positionLocked 允许 true、false 或旧 snapshot 的 undefined；运行时出现其他类型则拒绝，不让损坏状态进入
  FlatBuffer。
- 新增生产 decoder round-trip fixture，验证填充色逐位保真、锁定为 true，并验证透明 fill 抛错。
- 新增 ADR-0113 与 `d02-original-group-paste-shape-state.mjs`，同时锁定原版证据、encoder/decoder 字段、
  Group Paste 生产调用链及 Shape RichText 的保守门禁。

## 验证与边界

- 专项 replay 输出为
  `originalGroupPasteShapeState=type18-fill-lock-roundtrip-transparent-reject-richtext-gate-group-paste`；
  全量桌面 replay 为 `TOTAL=122 FAILED=0`，`git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 warning。未启动模拟器、虚拟机、真机或 Hypium。
- 本阶段只补齐普通 Shape 已由原版 type-18 直接表达的状态。Shape RichText、Image/Math、Styled/空 Text，
  以及剪切或非等比 transform 仍明确拒绝，不能降级成会丢 Group 或改变内容的普通 Paste。
