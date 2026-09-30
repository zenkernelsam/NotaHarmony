# Phase 1134 证据 — 布局管线 mr5/or5/nr5/k4c

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 类型

### `mr5{Object a, int b}` = 布局格/游标

`{值(any:常为 s3c), 索引}` 对——`s3c` 段迭代的带位
元素。`nr5.a(mr5)→mr5` 步进游标。

### `or5 implements rr5, nr5` = 运行时布局构建器

```java
{ sy8 a, b;          // 两构建态
  bka c, d;          // 双列表
  or5(pr5) ctor
  builder()→throw "Already a builder"   // 自己即构建器
  e()→List
}
```

是 `nr5`（layout engine）的**运行态实例**——规格→构建
对称里它就是构建器/`or5` 运行时。

### `nr5 extends mxc` = 布局引擎接口

`a(mr5)→mr5` 段步进；`builder()→or5`。

### `k4c implements j4c` = 布局宿主

```java
{ l4c a;        // 布局规格（Phase 1085）
  or5 b;        // 引擎实例
  mha c;        // mha(10) 通道
  double d;     // 参数
  e bool }      // 脏/flag
k4c(l4c)→new or5(l4c.b(nr5))  // 宿主由规格产引擎
```

## 管线

`e4c.g` 插入时经 `k4c.a(mr5)` 换算、`k4c.d()` 产物；
`n4c.b(or5,mr5)` 用 `or5.n()/a()` 步进 `s3c` 段。
`l4c`(规格)→`nr5/or5`(引擎)→`mr5`(游标)→`s3c`(段)。

## Harmony 决策

- 布局引擎宿主 `k4c`、运行时 `or5`、游标 `mr5{obj,idx}`。
- Harmony：引擎 + `{value,index}` 迭代游标。

## 产出

- fixture `d02-layout-pipeline.mjs`（10 断言）。
- ADR-1078；中文报告。
