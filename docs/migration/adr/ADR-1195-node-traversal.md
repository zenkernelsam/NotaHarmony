# ADR-1195：xp4 Modifier.Node 遍历/焦点

## 状态

已接受（Phase 1251）。

## 决策

`xp4` FocusEventModifierNode（`a0` kindMask+`K & 5120`
链走+`h1` 焦点变更）→ Harmony 组件树+focus 链+
`onFocus`。

## 理由

`xp4`=od8 Node：`a0`=kind-mask、`visitAncestors` 沿
`od8` 链 `K & 5120/3072/2048` 过滤、`k1`→`qz6` owner
—— 焦点事件遍历。

## 后果

Harmony 焦点遍历 = 组件树+focus+onFocus —— 遍历
语义保真。
