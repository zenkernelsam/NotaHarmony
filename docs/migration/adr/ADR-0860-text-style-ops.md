# ADR-0860 — 文本样式 op 四表（pub/me8/he8/io1）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `pub` RemoveChar{location:cxc, textField:qo5}。
- `me8` ModifyStyle 15 槽：v01 范围×2 + qo5 textField +
  **全 setter 包装**属性——z1d SetBool×7（bold/italic/
  underline/superscript/subscript/strikethrough/code）、
  g2d SetColor×2（highlight/foregroundColor）、
  z2d×2（familyName/link）、k2d SetFloat（size）。
- `he8` ModifyParagraphStyle 10 槽：裸 cxc start/end +
  枚举 setter 族扩展（o2d alignment、j2d decoratorStyle、
  a3d indentLevel、b3d writingDirection）+ k2d
  lineSpacing + z2d programmingLanguage + isChecked。
- `io1` ClearStyle{start,end:cxc, paragraph:bool,
  textField:qo5}。

## Harmony 决策

样式 op 编码对齐 setter 包装契约；段落样式裸 cxc
边界与枚举 setter 族对应实现。

## Parity 状态

等价（文本 op 族 8 表全闭）。

## 验证

- `d02-text-style-ops.mjs`：29/29 通过。
- 全量 Replay 789 文件绿，见 Phase 916 提交。
