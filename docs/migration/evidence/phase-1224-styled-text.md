# Phase 1224 证据 — 样式文本模型（a00=AnnotatedString / zqe=TextStyle）

来源：`defpackage/{a00,zqe,zz}.java`。

## `a00` = AnnotatedString

```java
final class a00 implements CharSequence {
    List I;              // annotation ranges (zz)
    String J;            // 文本
    ArrayList K;         // ← span-style 注记
    ArrayList L;         // ← paragraph-style 注记
    ctor: 按 zz 类型分 K/L 两列
}
```

`zz` = annotation range（item+start+end+tag）。

## `zqe` = TextStyle

```java
final class zqe {
    gnd a;               // SpanStyle（字符级）
    e5a b;               // PlatformTextStyle?
    ima c;               // ParagraphStyle（段落级）
    toString = "TextStyle(color=…, fontSize=…,
                 fontWeight=…, …)"
}
b()→f31 brush; c()→long color; d/e = merge/diff;
```

- `gnd` = **SpanStyle**（color/fontSize/fontWeight/brush…）
- `ima` = **ParagraphStyle**（textAlign/lineHeight/indent…）
- `f31` = Brush（渐变画刷）。

## 判定

Compose `AnnotatedString`+`TextStyle`+`SpanStyle`+
`ParagraphStyle`+`Brush` 实名栈 —— 字符/段落双层
样式注记进 `vpe` TextLayoutInput（Phase 1223）。

## Harmony 决策

`AnnotatedString`/`TextStyle`/`SpanStyle`/`ParagraphStyle`
→ ArkUI `StyledString`/`TextStyle`/`ParagraphStyle`
+ `AttributeModifier`；`f31` Brush → `LinearGradient`。

## 产出

- fixture `d02-styled-text.mjs`（10 断言）。
- ADR-1168；中文报告。
