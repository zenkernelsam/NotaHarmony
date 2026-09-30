# ADR-1209：Compose 语义/无障碍

## 状态

已接受（Phase 1265）。

## 决策

`tvc`/`ivc` 语义键注册表+`vvc` KProperty+`xvc` 写语义
→ Harmony `accessibilityText`/`accessibilityDescription`+
`onAccessibilityAction`。

## 理由

`tvc`=SemanticsProperties（ContentDescription/
editableText/textSelectionRange/imeAction…）；`ivc`=
SemanticsActions；`vvc`=33 KProperty+setter —— 无障碍
元数据（TalkBack 读取）。

## 后果

Harmony 无障碍 = accessibility*+onAccessibilityAction —
— 无障碍语义保真。
