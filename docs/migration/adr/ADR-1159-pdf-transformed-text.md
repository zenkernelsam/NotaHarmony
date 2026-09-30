# ADR-1159：pdf = TransformedTextFieldState

## 状态

已接受（Phase 1215）。

## 决策

`pdf` Compose `TransformedTextFieldState`（`qoe`
TextFieldState + `ov1`/`ps3` 变换 + output/visual 双
文本 + 偏移映射）→ Harmony `TextEditState` 自研
变换层（TextInput+TextController 掩码/格式）。

## 理由

`toString` 实名列出 `textFieldState/outputTransformation/
outputTransformedText/codepointTransformation/
outputText/visualText` —— Compose 新版文本域
`State`-变换架构实名确认。

## 后果

Harmony 文本域 = 提交层 output + 显示层 visual +
偏移映射 + `qoe.f(true)` undo 边界 —— 变换语义对齐。
