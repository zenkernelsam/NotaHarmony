# Phase 1264 证据 — a00/zqe AnnotatedString+TextStyle

来源：`defpackage/{a00,zqe,zz,gnd,e5a,ima}.java`。

## `a00` = `AnnotatedString`

```java
a00 implements CharSequence {
    List I;              // 注解范围 List<zz>
    String J;            // 文本
    ArrayList K,L;       // span-level / paragraph-level 二分
    a00(List, String) {
        // 遍历 zz → span (K) vs paragraph (L)
    }
}
```

`zz` = 注解记录 `{item, start, end, tag}`。

## `zqe` = `TextStyle`

```java
zqe { gnd a;             // SpanStyle（color/fontSize/weight）
      e5a b;             // ParagraphStyle
      ima c;             // PlatformStyle
      static d = default;
      a/f → copy; d(zqe)→merge-guard; e(zqe)→merge;
      toString "TextStyle(color=,fontSize=,fontWeight=…)"
}
```

## 语义

- `a00` = **Compose `AnnotatedString`** —— `List<zz>`
  注解按 span/paragraph 二分（`K`/`L`）;
- `zqe` = **Compose `TextStyle`** —— `gnd`(SpanStyle:
  color/fontSize/fontWeight/fontFamily/letterSpacing) +
  `e5a`(ParagraphStyle: textAlign/lineHeight/textIndent) +
  `ima`(PlatformStyle) + `d`/`e` merge;
- `gnd`/`e5a`/`ima` = Span/Paragraph/Platform style 三分。

## Harmony 决策

AnnotatedString+TextStyle → Harmony `StyledString`/
`TextStyle`+`Span`/`ParagraphStyle` —— 富文本语义保真。

## 产出

- fixture `d02-styled-text.mjs`（10 断言）。
- ADR-1208；中文报告。
