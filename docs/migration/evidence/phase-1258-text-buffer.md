# Phase 1258 证据 — o7a/dle/ele/jqe 文本缓冲

来源：`defpackage/{o7a,dle,ele,jqe,pz4,rh8,rnh}.java`。

## `o7a` = gap-buffer CharSequence

```java
o7a implements CharSequence {
    CharSequence I;           // 文本
    pz4 J;                    // char[] 缓冲
    int K,L;                  // gap/位置
    a(i,i2,charSeq,i3,i4) {   // replace
        char[] cArr = new char[max];
        // pz4.c char[] 拷贝 → gap-buffer 存储
    }
}
```

## `dle implements Appendable` = TextEditBuffer

```java
dle { ele I; f76 J; o7a K; rnh L; long M; jqe N; ql8 O; k1a P;
    static ele g(dle, long sel, jqe comp, int) {
        // → new ele(K.toString(), sel, comp, null, list, null)
    }
}
```

## `ele` = TextFieldCharSequence（不可变文本+选区）

```java
ele { List I,J; CharSequence K; long L; jqe M; k1a N;
    L = rh8.A(len, sel);           // 选区钳到文本长
    M = jqe(rh8.A(len, comp.a));   // 合成区钳位
}
```

## `jqe` = packed TextRange `long`

`{long a}` + `b=rh8.i(0,0)` + `d`=collapsed/`e`/`f`/`g`=
start/end/len —— `long` 打包 `start|end`。

## 语义

- `o7a` = **gap-buffer 文本存储**（`a`=`char[]` 拷贝
  replace —— 高效插入/删除）;
- `dle` = **`Appendable` TextEditBuffer** —— `ele`(当前)+
  `o7a`(存储)+`jqe`(选区)+`rnh`(终态)；`g()` 物化 `ele`；
- `ele` = 不可变文本+钳位选区（`rh8.A` 越界保护）；
- `jqe` = 打包 TextRange。

## Harmony 决策

gap-buffer+TextEditBuffer → Harmony 自研 CharSequence
缓冲+`TextRange` —— 文本编辑语义保真。

## 产出

- fixture `d02-text-buffer.mjs`（10 断言）。
- ADR-1202；中文报告。
