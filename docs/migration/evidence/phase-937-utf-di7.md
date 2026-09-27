# Phase 937 证据 — `utf` Uuid 线型 + `di7`/`ei7` 迭代器偏移

## `utf` = `Uuid`（xwd 16B inline，实证）

| 访问器 | 偏移 | 语义 |
|---|---|---|
| `d()` | `this.I + 0` | bitsHigh:long（MSB 先） |
| `c()` | `this.I + 8` | bitsLow:long |

`toString`: `"Uuid(bitsLow=N, bitsHigh=N)"`（
`njj.j0(10,…)` unsigned 格式）。`a()` 校验=null。
`ttf` 值类 {I,J:long} 的线型孪生——**MSB 在前**
（标准 UUID 大端）。

## `di7`/`ei7` = `hmf` 零拷贝字节迭代器

`cee.g(int)` = **ByteBuffer 切片访问器**（
length-prefixed 字节向量 → position 切片）。

### di7 构造 → 字段偏移（实证）

| 构造 | `g(N)` | 表字段 |
|---|---|---|
| `di7(wd8)` | g(20)/g(22)/g(24) | ModifyInk f9/f10/f11 路径向量 |
| `di7(dm2)` | g(24)/g(26) | CreateInk f10/f11 |
| `di7(gd)` | g(6)/g(8) | AddPathElements f1/f2 |
| `ei7(dm2)` | g(22) | CreateInk f9 中心路径 |

`I`=kind int、`J`=切片、`K`=position 起点、
`M`=num 值、`L`=游标；`a()`=size、`b()`=byte、
`hasNext()`。

## 结论

Uuid 线型 MSB-first 布局钉死；路径字节向量
经 `g(N)` 切片零拷贝逐字节读——印证 927
"encoded* = 原始字节向量"。
