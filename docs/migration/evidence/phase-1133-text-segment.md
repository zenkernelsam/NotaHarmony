# Phase 1133 证据 — s3c 样式文本段（双锚 span）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `s3c` = 样式文本段

```java
s3c { Set a, b;           // 属性集×2（样式/装饰）
      CharSequence c;     // 文本内容
      double d;           // 间距?
      int e;              // 偏移
      exc f, g;           // 起始/结束锚！
      Float h;            // 字号?
      int i, j }          // 计数（码点长）/端
```

- ctor 算 `iG` = `ry1.g()` 否则 `Character.codePointCount`
  —— **码点长度**（非 UTF-16 长度）。
- 双 `exc` 锚 `f`(start)/`g`(end) —— 段在 CRDT 序列里占
  `[f..g]` 区间。

## `s3c.a(s3c, cs, i, exc, exc2, flags)` = copy-with 工厂

Kotlin `copy()`：按 `111` 位掩码局部覆盖字段产新段（插入时
`or5.n(mr5, s3c.a(seg,null,i,null,null,111))` 用它派生分裂段）。

## 与 e4c.g 配对

插入分裂 → `new s3c(subSeq, e+knb, exc, excD, k3c.a, prev)`；
`k3c.a` = 空属性集。

## `ry1` CharSequence

自带 `g()` 码点长 + `i(i)` 索引换算 —— 预布局文本类型。

## Harmony 决策

- 段 = `{attrs, text, offset, 锚 f..g, cpLen}`；
  copy-with 用掩码派生；码点长度计。
- Harmony：用 Record + partial-copy 复刻。

## 产出

- fixture `d02-text-segment.mjs`（10 断言）。
- ADR-1077；中文报告。
