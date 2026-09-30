# Phase 1265 证据 — tvc/vvc/ivc/xvc Compose 语义/无障碍

来源：`defpackage/{tvc,vvc,ivc,xvc,wvc,wk8}.java`。

## `tvc` = SemanticsProperties 键注册表

```java
static wvc a = "ContentDescription";
static wvc b = "StateDescription";
static wvc c = "ProgressBarRangeInfo";
static wvc d = "PaneTitle";
static wvc h = "Heading"; i = "TextEntryKey";
j = "Disabled"; k = "LiveRegion"; l = "Focused";
m = "IsContainer"; ...
```

## `ivc` = SemanticsActions 键注册表

`wvc A`–`j` —— onClick/onLongClick/requestFocus/
setText/setSelection/copy/cut/paste/scrollToIndex/
showOnScreen 等动作键。

## `vvc` = 33 KProperty accessor + setter helpers

`fl6[] a` = `wk8` KProperty 数组（stateDescription,
editableText, textSelectionRange, textCompositionRange,
imeAction, selected, customActions, contentType,
fillableData...）+ `a`-`l` 静态 setter（`setSemanticsAction`）。

## `xvc` = SemanticsPropertyReceiver iface

`xvc.g(wvc key, value)` = 写语义属性。

## 语义

- `tvc`/`ivc` = **Compose 语义/无障碍属性+动作键**
  —— TalkBack/无障碍服务读的元数据（editableText/
  textSelectionRange/imeAction + click/scroll 动作）；
- `vvc` = KProperty 绑定 + setter；
- `vle.h(xvc)` = 编辑域语义填充（Phase 1206）→
  editableText/selectionRange/compositionRange/imeAction/
  customActions → TalkBack+autofill。

## Harmony 决策

SemanticsProperties/Actions → Harmony
`accessibilityText`/`accessibilityDescription`+
`accessibilityGroup`+`onAccessibilityAction` —— 无障碍
语义保真。

## 产出

- fixture `d02-semantics.mjs`（10 断言）。
- ADR-1209；中文报告。
