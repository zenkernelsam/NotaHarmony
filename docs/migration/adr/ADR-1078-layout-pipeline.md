# ADR-1078：文本布局管线

## 状态

已接受（Phase 1134）。

## 决策

- `l4c`（规格）→ `k4c`（宿主，`j4c`）→ `or5`（运行时
  构建器，`rr5,nr5`）→ `mr5{Object,int}` 游标步进 `s3c` 段。
- `or5.builder()` 自返回语义（"Already a builder"）；
  `mha(10)` 通道缓冲。

## 依据

`or5 implements rr5,nr5` + `k4c(l4c)` ctor 产 `or5`；
`n4c.b(or5,mr5)` 步进段。

## 后果

Harmony：布局引擎宿主 + 运行时 + `{value,index}` 迭代；
通道缓冲容量 10。
