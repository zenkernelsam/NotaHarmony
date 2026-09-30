# Phase 1276 证据 — mmf/njj/ft9/tr2 打包ID+实体解码+GraphQL操作

来源：`defpackage/{mmf,njj,ft9,tr2,qo5}.java`。

## `mmf` = 打包 int value-class

```java
mmf{int I} implements Comparable
a(i) = String.valueOf(i & 0xFFFFFFFFL)  // 无符号
```

→ 无符号打包 ID（`qo5.d()` 的类型/紧凑字段）—
`qo5` = `{a=String uuid, c=short type, d=mmf uint}`。

## `njj.A(cee)→qo5` = FlatBuffers 实体-ID 解码器

```java
static qo5 A(cee table)   // 从任意表读 qo5 实体-id
j0(10, long) = Long.toString base10
C/D(pd8, ix4) = Modifier helpers; px1 c/d = 常量
```

→ `njj` = R8 合并的 Compose+FlatBuffers 助手类。

## `ft9` = GraphQL `Operation` iface

`{c()→String, id()→String, name()→String}` —— Apollo
操作（id/name/document 串）。

## `tr2 implements r24` = Apollo CustomScalarAdapters

`{Set a, Set b, Map c}` + `getKey()→s24` —— Apollo
响应适配上下文（自定义标量序列化器注册表）。

## 语义

`qo5` 实体 ID = `{uuid 串, short type, mmf uint}` —
— CRDT 实体寻址；`njj.A` 从 FlatBuffers 表解码它；
`ft9`/`tr2`/`o20` = GraphQL 操作+适配 —— op 编码
→ 同步协议桥。

## Harmony 决策

打包 ID+FlatBuffers 解码+GraphQL op → Harmony
`type ID{uuid,type:uint}`+二进制解码+GraphQL 操作 —
— 实体寻址+同步协议保真。

## 产出

- fixture `d02-id-encode-graphql.mjs`（10 断言）。
- ADR-1220；中文报告。
