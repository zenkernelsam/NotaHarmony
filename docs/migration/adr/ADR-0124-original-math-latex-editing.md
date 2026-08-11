# ADR-0124: 原版 Math LaTeX 编辑与 MODIFY_BLOCK field 10 出站

## 状态

已采纳，2026-08-12。本文 supersede ADR-0063 中“LaTeX 内容编辑与 MODIFY_BLOCK writer 未完成”的部分；
原生公式排版引擎和设备像素验收边界保持不变。

## 原版证据

- `dhb` 的单 Math selection menu 分支读取 `u08.R()`，以 block operation ID 和当前 LaTeX 构造
  `x08(Edit)`。
- `v08/y22/z22` 构成固定宽度 Math editor：标题、输入区、Cancel、Done，以及 Empty/Loading/Invalid/Ok
  四态；只有 `owa(Ok)` 允许 Done。
- `n07` 的 Done 回调把当前 draft 与 `z08` 交给异步提交；外层 `u49` 使用
  `feature_note__math_editor_failed` 报告提交失败。
- `td8` field 10 是 nullable Math LaTeX setter；setter field 0 是 UTF-8 string。现有 Harmony reducer 已按
  LWW winner 将该 register 物化回 `MathElement.latex`。

## 决策

- 只有直接选择一个、且 identity 可解码的 Math 时显示 `Edit Math`。Group、多选和混合选择不显示。
- overlay 预填当前 LaTeX；Cancel 不修改任何内存、历史或数据库状态。空白、非法 UTF-8 round-trip 或超过
  1 MiB decoder budget 的 draft 禁用 Done。
- `encodeOriginalMathLatex()` 写 type-23 的 blocks vector 和 field-10 setter string。普通编辑写 present
  string；空字符串仍允许编码，供 Undo 恢复合法的既有空 register。
- persistence classifier 只接受 identity/order 不变、恰好一个 Math 且只有 `latex` 改变的 snapshot。
  提交在一个 SQLite transaction 内完成 operation identity 分配、reducer、page revision batch、
  upload-immediate operation、canonical snapshot equality 和 persistent-history companion。
- UI 在 durable transaction 成功后才替换画布 Math 并压入 Undo 栈。失败时保留 overlay、draft 和原内存态，
  允许重试或 Cancel；不会留下会在后台意外重试的 dirty save boundary。
- Undo/Redo 的普通与 grouped history 路径复用同一 classifier/writer，因此反向 LaTeX 也生成新的原版
  type-23 operation，而不是退化为本地整页快照。

## 校验边界

Harmony 当前没有原版使用的公式 bitmap/layout engine。本阶段不编造 LaTeX parser，也不把 raw LaTeX
文本伪装成公式排版；静态门禁只证明非空、UTF-8 与预算合同。完整语法 Invalid/Ok 判定、公式排版、尺寸回写
和像素一致性必须在后续引入等价引擎并进行设备验收。

## 验证

- `d02-local-math-latex-edit.mjs` 锁定原版菜单、状态、Done/失败证据和 Harmony transaction/UI 接线。
- ArkTS fixture 覆盖 field-10 setter round-trip、空字符串 Undo、目标/预算拒绝、单 Math 严格 classifier、
  reverse Undo、混合字段拒绝和 draft 门禁。
- 全量 replay 与 clean 双 HAP 结果记录在 Phase 147 总结；未启动设备或 Hypium。
