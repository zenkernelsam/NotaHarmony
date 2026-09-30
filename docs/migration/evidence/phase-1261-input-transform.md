# Phase 1261 证据 — bg4/d28/nv1/z36/a46 输入变换链

来源：`defpackage/{bg4,d28,nv1,z36,a46}.java`。

## `a46` = `InputTransformation` iface

`i(dle)` = 对 TextEditBuffer 变换 + `h(xvc)` semantics。

## `bg4` = `.then` 链式组合

```java
bg4 implements a46 { a46 a, b;
    i(dle) { a.i(dle); b.i(dle); }   // a.then(b)
}
```

## `d28` = `.maxLength(6)`

`i(dle)` 截断；`toString`="InputTransformation.maxLength(6)"。

## `nv1` = hex 颜色 filter

`i(dle)` 过滤非 hex 字符（# + 0-9a-fA-F）—— 颜色
输入字段。

## `z36` = passthrough 单例 `a`

## 语义

- `a46` = **`InputTransformation`**（文本输入变换接口）；
- `bg4` = **`.then` 链**（复合变换 a→b）;
- `d28` = `.maxLength(6)`（长度截断）；
- `nv1` = **hex 颜色输入过滤器**（颜色字段只允许
  `#`+hex）;
- `z36` = passthrough（恒等）;
- `pdf`/`vle` 用 `bg4`/`d28`/`nv1`/`z36` 组合字段输入
  规则。

## Harmony 决策

InputTransformation → Harmony `TextInput` `onWillChange`/
`inputFilter`+自研变换链 —— 输入过滤语义保真。

## 产出

- fixture `d02-input-transform.mjs`（10 断言）。
- ADR-1205；中文报告。
