# Phase 1084 证据 — cie/hp5 成员集合实体 + m4c 集合 spec + dp5

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 成员集合实体（块 spec 变体，持 `m4c`）

| 类 | implements | 关键字段 |
|----|-----------|---------|
| `cie` | xy0,xhe,be5,bf0,ce5 | `ry0 b` + `m4c c` + `vy7 f` + xgb |
| `hp5` | xy0,be5,bf0,ce5,oy0 | `ry0 b` + `m4c d` + `dp5 g` + `String i` |

- `cie` 委托属性 {paper, resizesWidthToFitText} —— 文本块。
- `hp5` = 媒体/附件块（`dp5` payload 详情 + `i` 字符串）。
- 两者 `b` 都指 `ry0` 块 spec —— 块可含子集合（嵌套）。

## `m4c implements qg2,o4c,t3c` = 成员集合 spec

```java
m4c(int, vy7 margins, Float, int, bool, bool,
    List h, double, l4c, bxc, hja, cl2, List n)
static m4c D(...)                    // copy-with
```

集合布局参数：margins + 纵横比 + 子项列表 + `l4c`/`bxc`/
`hja`/`cl2` 细节。

## `dp5 extends cee implements ka4`

块详情表：`j()`/`k()` 校验（`ddg.i`）。

## Harmony 决策

- 块实体经 `m4c` 持子集合（嵌套块树）。
- `m4c` 集合 spec 布局参数原样。

## 产出

- fixture `d02-member-collection.mjs`（10 断言）。
- ADR-1028；中文报告。
