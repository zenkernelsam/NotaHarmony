# Phase 1198 证据 — 文本输入/IME（a46 sink + nn6=KeyboardOptions）

来源：`defpackage/{a46,nn6,xvc}.java`。

## `a46` = 文本编辑 sink iface

```java
interface a46:
  h(xvc)          // 编辑回调
  i(dle)          // **消费文本编辑**（dle=Appendable 编辑，
                  //  → CRDT apply）
  j()→nn6          // →KeyboardOptions（IME 配置）
```

## `nn6` = **Compose `KeyboardOptions`**（toString 实名）

```java
"KeyboardOptions(
   capitalization, autoCorrectEnabled,
   keyboardType, imeAction, platformImeOptions,
   showKeyboardOnFocus, hintLocales)"
```

Compose `KeyboardOptions` —— 文本输入 IME 配置
（大小写/自动纠错/键盘类型/IME 动作/焦点弹键盘/
提示 locale）—— 笔记文本编辑用 Compose `TextField`。

## `xvc` = 编辑回调 iface `g(wvc, Object)`

## 判定

**文本输入 = Compose `TextField` + `KeyboardOptions`**：
`a46` sink 收 `dle` 编辑（→CRDT）+ `j()→KeyboardOptions`
IME 配置 + `xvc` 回调 —— Compose TextField 体系。

## Harmony 决策

- `KeyboardOptions` → Harmony **`TextInput`/
  `TextArea` 属性**（`enterKeyType`/`maxLength`/`inputFilter`
  /capitalization/`showKeyboardOnFocus`）—— ArkUI 文本
  输入属性对应。
- `a46` sink → Harmony 编辑 sink（`dle` 编辑→CRDT）。

## 产出

- fixture `d02-keyboard.mjs`（10 断言）。
- ADR-1142；中文报告。
