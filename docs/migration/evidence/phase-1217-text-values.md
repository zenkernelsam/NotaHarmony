# Phase 1217 证据 — 文本值层（ele/jqe/k1a/dle）

来源：`defpackage/{ele,jqe,k1a,dle}.java`。

## `jqe` = packed TextRange

```java
final class jqe {
    static final long b = rh8.i(0,0);     // 空 (0,0)
    long a;                                // start<<32|end
    static a(j,j2) = g(j)<=g(j2) && f(j2)<=f(j)  // 包含
    static c(j,j2)                          // 交叠/相等
    static d(j) = (j>>32)==(j&0xFFFFFFFF)   // 坍缩
}
```

`g()`=`>>32` start、`f()`=`&0xFFFFFFFF` end。

## `ele` = TextFieldCharSequence（不可变文本态）

```java
ele implements CharSequence {
    List I, J;          // 注记列表×2（composition/spans）
    CharSequence K;     // 文本
    long L;             // 选区 packed
    jqe M;              // 组合区 TextRange
    k1a N;              // 带数据区域
    ctor: L/M/N 都经 rh8.A(len,·) 钳位至文本界
}
charAt/length/subSequence/toString → K 委托
```

## `k1a` = Serializable 区间数据

`{Object I, Object J}` —— 区域载荷（IME 组合属性/
span 数据）。

## `dle` = TextEditBuffer（可变编辑构建器）

```java
dle implements Appendable {
    ele I;              // 原文本态
    long L,M; jqe N;    // 选区/组合
    Appendable append(CharSequence/char/subseq) ×3
}
```

构造：`new ele(str, rh8.A(len,j), null,null,null, 60)`
—— 位掩码可选字段；`c(pos,pos+len,text)` 替换。

## 判定

Compose `TextFieldCharSequence`+`TextEditBuffer`+
`TextRange` 完整文本值栈 —— `ele` 不可变值 +
`dle` 可变编辑 + `jqe` packed 区间 + `k1a` 区域载荷；
所有区间构造经 `rh8.A` **钳位**（防越界选择）。

## Harmony 决策

`ele`/`dle`/`jqe`/`k1a` → ArkTS `TextEditState`/
`TextRange{start,end}` packed（`hi<<32|lo`）+ 可变
builder；钳位语义保留。

## 产出

- fixture `d02-text-values.mjs`（10 断言）。
- ADR-1161；中文报告。
