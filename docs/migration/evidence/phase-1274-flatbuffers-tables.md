# Phase 1274 证据 — cee/vq9/uq9/qo5 FlatBuffers 表

来源：`defpackage/{cee,vq9,uq9,qo5,xwd,zq6,ka4}.java`。

## `cee` = FlatBuffers `Table` 基类

```java
abstract cee {
    int I;                 // bb_pos（缓冲区位置）
    ByteBuffer J;          // bb（数据缓冲）
    int K, L;              // vtable/offset
    zq6 M;                 // utf8 decoder
    int b(int)             // __offset（vtable 查找）
    String e(int)          // __string（读 UTF-8 串）
    void d(int, ByteBuffer)// __reset（复用解析器）
}
```

## `uq9 extends cee implements ka4` = 顶层 op 表

```java
a()→String;   k()→long;        // 名称 + 时间戳
l()/p()→qo5;  // 实体 ID（qo5）
j()/n()→tmf;  m()→haa; o()→sdf;// 嵌套载荷表
```

→ 文档 op（entity id + ts + 嵌套变更载荷）— CRDT delta。

## `qo5 extends xwd implements ka4` = ID/实体记录

`{a()→String, c()→short, d()→int}` —— 紧凑 ID
（type+version+uuid 字符串）。

## `vq9 extends cee implements ka4` = op 载荷表

`a()/l()→String`+`j()→Boolean`+`k()→qo5`+`m()/n()→uq9`
—— 载荷包进 `uq9` op。

## `xwd`/`zq6`/`tmf`/`haa`/`sdf`

`xwd`=Struct 基类；`zq6`=Utf8 decoder；`tmf`/`haa`/`sdf`=
嵌套载荷表（op 的具体变更数据）。

## 语义

**FlatBuffers 生成表** —— `cee` Table+`xwd` Struct +
`ka4` 标记；`uq9` op=`qo5` 实体 ID+ts+嵌套载荷 —
— 文档 CRDT 变更的二进制编码（可序列化/同步）。

## Harmony 决策

FlatBuffers → Harmony 无官方运行时 —— 手写二进制
read/write 保格式，或 `flatbuffers` TS 移植 ——
op 编码语义保真。

## 产出

- fixture `d02-flatbuffers-tables.mjs`（10 断言）。
- ADR-1218；中文报告。
