# ADR-0886 — 样式 op 偏移图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `me8` ModifyStyle 15 字段：v01 范围 + qo5 +
  bold/italic/underline/highlight/family/size/
  fgColor/link/super/sub/strike/code 全 setter。
- `he8` ModifyParagraphStyle 10 字段：**cxc**
  范围 + indent/alignment/lineSpacing/decorator/
  isChecked/textField/progLang/writingDir。
- `io1` ClearStyle 4 字段。
- **层级差异**：字符样式 v01 边界 vs 段落
  样式 cxc 位置。

## Harmony 决策

范围类型差异（v01↔cxc）语义对齐。

## Parity 状态

等价。

## 验证

- `d02-style-ops.mjs`：30/30 通过。
- 全量 Replay 815 文件绿，见 Phase 942 提交。
