# Phase 897 证据 — 叶子校验体 + `vy7` 字段序 + `ymf`=UShort

## 目的

实名 ka4 叶子校验体；钉死 vy7 边距字段序；实名
ymf 值类。`decompiled_1.0.3`。

## 叶子校验体（实证）

- `k3a.a()`：`hu1.c() & 255 < 255` → `"Paper background
  colors must be alpha == 1"`——纸面颜色 alpha 必须
  0xFF（不透明）。
- `vy7.a()`：四边 <0 → `"Margins cannot be negative"`；
  逐边 `ddg.l("left"/"right"/"top"/"bottom", …)` 有限性。
- `qed.a()` = `ddg.i(this)`（尺寸≥0+有限性委托）。
- `fqa.a()` = `ddg.h(this)`（点 x/y 有限性委托）。

## `vy7` 字段序钉死（TBLR）

`a()` 内 `l()` 调用顺序实证：

| 偏移 | 访问器 | 语义 |
|------|--------|------|
| +0 | `f()` | **top** |
| +4 | `c()` | **bottom** |
| +8 | `d()` | **left** |
| +12 | `e()` | **right** |

与 `ddg.g` 交叉验证：`e()+d() > qed.d()` =
right+left > width（横向）；`c()+f() > qed.c()` =
bottom+top > height（纵向）——自洽。

## `ymf` = UShort 值类

```java
public final class ymf implements Comparable {
    public final short I;
    toString() = a(this.I)   // 无符号 short 格式化
}
```

- 与 `mmf`=UInt 同构 → `ymf`=Kotlin **UShort**。
- vt9 字段1 schemaVersion 的包装类型；`ar6.K`=15
  当前值以 UShort 语义上线。

## Harmony 侧

- 纸色 alpha=0xFF 门 ↔ Harmony 纸面颜色校验；
  边距 TBLR 序 ↔ vy7 16B 编码（887 已对齐布局，
  本次实名字段序）；ymf UShort ↔ schema 版本读取。

## 结论

叶子校验体+vy7 TBLR 序+ymf=UShort 实名；
值类家族补全（UInt/UShort）。纯文档+fixture 阶段。
