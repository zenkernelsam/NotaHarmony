# Phase 1278 证据 — i9h/s7h/g9h/h9h protobuf-lite 基础设施

来源：`defpackage/{i9h,s7h,e9h,g9h,h9h,a7h}.java`。

## `h9h` = `RawMessageInfo`（codegen 字段布局描述符）

```java
h9h{z6h a=defaultInstance, String b=info,
    Object[] c=objects, int d=flags}
```

→ protobuf-lite 的**免反射字段编码**：`buildMessageInfo`
产出的压缩字段表（String info=字段号/类型编码，
objects=oneof/map/enum 引用）—— Schema 据此直接
读写 wire。

## `g9h extends a7h implements RandomAccess` = `ProtobufArrayList`

`{Object[] J, int K size}` + 扩容 `e(i)` —— protobuf
repeated-field 的数组后备（`Internal.ProtobufList`）。

## `s7h` = `ExtensionRegistryLite`

`volatile a` + `static b`(EMPTY) —— 解析时的扩展
注册表（parseFrom 第 3 参）。

## `i9h`/`e9h` = Schema/内部 iface

`i9h`=protobuf `Schema`（`z6h.b(i9h)` writeTo）；`e9h`=
内部标记（ProtobufList/IntList 等）。

## `a7h` = AbstractProtobufList 基类。

## 语义

**protobuf-lite 免反射 codegen 基础设施** —— `h9h`
RawMessageInfo 是核心：生成代码把字段布局编成
String+Object[]，运行时 Schema 直接据此序列化/
解析（无反射）。

## Harmony 决策

protobuf-lite codegen → Harmony 手写 wire+字段表或
protobuf-ts —— `RawMessageInfo` 式压缩字段描述符
可手工构造。

## 产出

- fixture `d02-proto-infra.mjs`（10 断言）。
- ADR-1222；中文报告。
