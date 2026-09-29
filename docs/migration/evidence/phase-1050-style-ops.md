# Phase 1050 证据 — 样式操作载荷 + 段落枚举

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `me8` ModifyStyle（15 字段）

`{start, end, textField:qo5, bold, italic, underline,
highlight, familyName, size, foregroundColor, link,
superscript, subscript, strikethrough, code}`

校验：familyName 非空（"Cannot set familyString to
empty"）；size>0（"Font must be > 0"）。

## `he8` ModifyParagraphStyle（10 字段）

`{start, end, indentLevel, alignment:o2d→r4a,
lineSpacing, decoratorStyle:j2d→fy2, isChecked(deprecated),
textField:qo5, programmingLanguage, writingDirection:
b3d→bcg}`

校验：isChecked 已废弃（"isChecked is deprecated, use
UpdateCheckbox"）；无样式拒绝（"No paragraph styles
specified"）；空范围拒绝（"Empty range: start and end
cannot point at same seqId"）。

## `io1` ClearStyle

`{start, end, paragraph, textField}`——校验 start/end
锚点类型：`l().d()`/`j().d()` ordinal 检查，
非法类型 → "Invalid start type: ..."（`o14.t()` 兜底）。

## 段落枚举（byte wrapper 模式：o2d/j2d/b3d 包 byte）

| 枚举 | 值 |
|---|---|
| `r4a` 对齐 | **LEFT=1** CENTER=2 RIGHT=3（1 基） |
| `fy2` 装饰 | NONE=0 BULLET=1 NUMBER=2 CHECK_BOX=3 BLOCK_QUOTE=4 CODE_BLOCK=5 |
| `bcg` 方向 | LEFT_TO_RIGHT=0 RIGHT_TO_LEFT=1 |

## HarmonyOS 决策

- 15/10/4 字段布局与校验文案保留；
  `isChecked` 废弃→引导 UpdateCheckbox 语义保留；
  r4a **1 基**编码注意保留（0=未设）。

## 产出

- fixture `d02-style-ops.mjs`（12 断言）。
- ADR-0994；中文报告。
