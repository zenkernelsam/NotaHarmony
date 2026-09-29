# Phase 1116 证据 — kci.j op 重序列化 + dbj.c v71 零拷贝 + sg5.b scratch

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `kci.j(f46, a)` = op 表复制/重序列化

```java
ByteBuffer bb = sg5.b.get();
ByteBuffer str = bb != null ? f46.h(6, bb) : f46.g(6);  // 取 string
a.C(3); a.h(1, a.m(str));               // 重创 string
if (exc != null) a.j(0, sg5.f(a, exc)); // 重嵌锚
if (qo5 != null) a.j(2, rh8.O(qo5, a)); // 重嵌 opId
return a.n();                           // endTable → offset
```

把一个 `f46` 表复制进新 builder（op 重写/再打包路径）。

## `dbj.c(CharSequence, a)` = createString + v71 零拷贝

```java
if (!(cs instanceof v71)) return a.l(cs);     // 普通字符串
ByteBuffer bb = sg5.b.get();                  // 线程本地 scratch
return a.m(bb != null ? ((v71)cs).f(bb)       // v71 字节直灌
                      : ((v71)cs).e());
```

`v71` = ByteBuffer-backed CharSequence —— 字节直接进 builder
的 ByteBuffer（零拷贝，免 UTF-8 重编）。

## `sg5.b` = `ThreadLocal<ByteBuffer>` 序列化 scratch

## Harmony 决策

- op 重写 = 重序列化表（新 builder 内重建字段）。
- 字节串 CharSequence 走零拷贝 ByteBuffer 通道。
- thread-local scratch buffer。

## 产出

- fixture `d02-op-reserialize.mjs`（10 断言）。
- ADR-1060；中文报告。
