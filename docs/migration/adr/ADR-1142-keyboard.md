# ADR-1142：文本输入/IME（KeyboardOptions）

## 状态

已接受（Phase 1198）。

## 决策

`nn6`=Compose `KeyboardOptions`（capitalization/autoCorrect/
keyboardType/imeAction/platformImeOptions/showKeyboardOnFocus/
hintLocales）→ Harmony `TextInput`/`TextArea` 属性
（enterKeyType/capitalization/inputFilter/showKeyboardOnFocus）；
`a46` sink `i(dle)` 编辑→CRDT + `j()→KeyboardOptions`。

## 理由

`nn6.toString` 实名 KeyboardOptions 7 字段 + `a46`
`i(dle)`/`j()`/`h(xvc)`。

## 后果

文本编辑 = ArkUI TextInput + KeyboardOptions 语义映射；
编辑 sink 收 dle→CRDT。
