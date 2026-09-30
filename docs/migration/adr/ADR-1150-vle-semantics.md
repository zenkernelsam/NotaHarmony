# ADR-1150：vle 语义/自动填充层

## 状态

已接受（Phase 1206）。

## 决策

`vle.h(xvc)` Compose Semantics + `AutofillValue`
文本域填充 → Harmony `accessibilityText`/
`accessibilityDescription` + 自动填充框架；
`j1` 动作码 5/6/7 → 自定义动作表。

## 理由

`xvc`=`SemanticsPropertyReceiver`、`tvc`=键注册表、
`vle.h` 填 editableText/selectionRange/compositionRange/
imeAction/AutofillValue.forText —— TalkBack+autofill
完整暴露。

## 后果

Harmony 编辑域无障碍 = 文本/选区/组合区语义 +
自动填充对齐 —— 无障碍行为保真。
