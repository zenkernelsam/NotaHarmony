# Phase 1151 证据 — cz8 ThreadLocal 表访问器 + sg5 注册表

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `sg5` 静态字段 = 12 cz8 holder 注册表

```java
b  = ThreadLocal                            // 裸 scratch
c..n = new cz8(factory, bh4(idx))           // 12 表访问器
o  = d1                                     // OpAck?
a()→qo5; b()→cxc; c()/d()→List; e()→AtomicBoolean
f(a,exc)→int; g(List)→ix4
```

`fl6[] a` 描述符把 `c..n` 映到 `core.flatbuffers.*`：
`Id/SeqId/StyleMap/RecordingSegment/Point/Size/
ModifyPosition/DuplicateOp/OpAck/Op`（Phase 1117 名）。

## `cz8 extends ThreadLocal` = 线程局部表访问器

```java
Function0 a;   // 生成类工厂（pg5.I=Id、og5.I=SeqId…）
ix4 b;         // 槽绑定 lambda（bh4(idx)）
initialValue() = a.invoke()                  // 懒建表
get() = super.get() + b.invoke(obj)          // 取+绑槽 idx
a() = super.get()                            // 裸取
```

**每线程复用 FlatBuffers 表**：`get` 返回线程本地表并
按 `bh4(idx)` 绑定槽 —— 零分配热路径读。

## `bh4 implements ix4` = 槽绑定 lambda

`bh4(int I)` 合成类捕获槽索引 —— `bh4(8)` = 绑槽 8
（Id 的字段槽）。

## `pg5`/`og5` = 生成类工厂

`pg5.I`/`og5.I` = `core.flatbuffers.Id`/`SeqId` 生成类的
`new`/`getRootAs` provider lambda（混淆名 ↔ 真 schema 名
经 `sg5` 描述符映射）。

## Harmony 决策

- 每线程 FlatBuffers 表 = `ThreadLocal{factory, slotBind}`
  —— Harmony 用 `AsyncLocal`/单线程模型下免分配池。
- schema↔混淆类映射经 `sg5` 描述符。

## 产出

- fixture `d02-cz8-holders.mjs`（10 断言）。
- ADR-1095；中文报告。
