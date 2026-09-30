# Phase 1191 证据 — 文本编辑记录（ele/dle，undo 用）

来源：`defpackage/{ele,dle,qoe}.java`。

## `ele implements CharSequence` = 文本编辑记录

```java
ele: {List I, List J, CharSequence K, long L}
```

CharSequence 实现 + 2 List + 文本 + 时间戳 —— **文本
编辑 op 记录**（撤销用，描述一次文本 change 的范围/
内容）。

## `dle implements Appendable` = 文本编辑构建器

```java
dle: {ele I, f76 J, o7a K, rnh L}
```

Appendable 实现 —— 累积文本编辑构建成 `ele` 记录。

## `qoe` = undo 消费者（会话类）

`{String,long,wx5}` + `b(dle)` + `e(ele,ele,rnh,bme)` —
编辑会话把 `dle`/`ele` 编辑记录配 `bme`(enum) 入 undo。

## 判定

文本编辑 undo = `dle`(Appendable 累积) → `ele`
(CharSequence 编辑记录{2 List+文本+ts}) → `nnf` op 栈
（Phase 1190）—— 编辑记录成 CharSequence 形态
（范围+内容+ts），可逆 apply。

## Harmony 决策

`ele`/`dle` → Harmony 文本编辑记录 + Appendable 等价
（`StringBuilder` 风格累积）→ undo op 栈。

## 产出

- fixture `d02-text-edit.mjs`（10 断言）。
- ADR-1135；中文报告。
