# ADR-0882 — l2d/ee8/mqf 字段布局

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `l2d` SetMetadata 8 字段精确镜像 a79 寄存器：
  title/pageBackground/handwritingLanguage/
  alignTextToLines（setter-wrapped）+
  defaultFontFamily/defaultFontSize/layoutMode/
  blockWrapSupport（裸值）。
- `ee8` ModifyPDFField{assetHash,key,valueType,
  valueString,valueBoolean}。
- `mqf` UpdateCheckbox{textField,location,
  isChecked}。

## Harmony 决策

字段布局对齐。

## Parity 状态

等价。

## 验证

- `d02-l2d-ee8-mqf.mjs`：17/17 通过。
- 全量 Replay 811 文件绿，见 Phase 938 提交。
