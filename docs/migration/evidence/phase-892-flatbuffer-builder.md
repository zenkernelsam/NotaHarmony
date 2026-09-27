# Phase 892 证据 — `a` = FlatBufferBuilder 原语层 + `hu1` = Color

## 目的

钉死全部序列化证据依赖的 `aVar.X` 原语映射
（`com/google/flatbuffers/a.java` = 混淆 FlatBufferBuilder）。

## 原语映射（逐方法实证）

| 调用 | 语义 | 证据 |
|------|------|------|
| `C(i)` | **startTable**(i 字段)：`d[i]` 槽数组、f=嵌套守卫 | "object serialization must not be nested" |
| `D(i,i2,i3)` | **startVector**(元素宽 i, 数 i2, 对齐 i3)：`t(4,i*i2)`+`t(i3,i*i2)` | 同上守卫 |
| `n()` | **endTable**：裁剪尾零槽、写 vtable+SOffsetT | "endTable called without startTable" |
| `o()` | endVector（D 分支内 `return o()`） | b() 体 |
| `z(off,4+2i)` | **required(field i)**：vtable 槽非零断言 | "field N must be set" |
| `a(i,z,z2)` | addBoolean(槽,值,默认)：`l\|\|z!=z2` 条件写 | 方法体 |
| `e(i,v,d)`/`c(i,b,d)` | addInt/addByte(默认跳过) | 序列化点 |
| `h(i,off)`/`j(i,soff)` | addOffset/addStruct | 序列化点 |
| `s(i)`/`t(i,i2)` | pad/prep(对齐,尺寸) | nti.X s(2)=两字节零填充 |
| `r()`/`B(i)` | offset()/slot(i) 记录字段位 | B(i)=`d[i]=r()` |
| `q()` | 完成缓冲守卫 | sizedByteArray 前 |

## required 槽公式破解（4+2·字段号）

- `wa0` z(4),z(6),z(8) → **field0/1/2 必填**（assetHash,
  fileName, mimeType；fileSize 非必填）。
- `sw9` z(4),z(14) → **field0/5 必填**（metadata, cropBoxes）。
- `uq9` z(4),z(14)（860）→ field0/5 = **id+payload 必填**✓。
- `tdf` z(4)（862）→ field0 interactionId 必填✓。

## `hu1` = `Color` 4B RGBA 结构（toString 实证）

`Color(bitsR=, bitsG=, bitsB=, bitsA=)`——`f/e/d/c()` 四个
byte 访问器；`cmf.a(byte)` = 无符号字节格式化。
k3a 字段4 的颜色 = 内联 RGBA×4byte 结构。

## Harmony 侧

`OriginalFlatBufferTableReader`/手写编码器的 prep/slot/
vtable 语义 = 此原语集一一对应；required 断言 ↔
Harmony 必填字段门；hu1 ↔ 颜色编码（RGBA 4B）。

## 结论

全部 `aVar.X` 调用 = 标准 FlatBufferBuilder 原语；
required 公式 4+2i 统一破解历史证据；hu1=Color RGBA
实名。原语层闭合。纯文档+fixture 阶段。
