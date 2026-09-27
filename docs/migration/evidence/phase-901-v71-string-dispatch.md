# Phase 901 证据 — `dbj.c` 字符串写派发 + `v71` 原始 UTF-8 视图

## 目的

实名所有表字符串字段的写路径。`decompiled_1.0.3`。

## `dbj.c(CharSequence, a)` = 字符串写派发（实证）

```java
public static final int c(CharSequence cs, a aVar) {
    if (!(cs instanceof v71)) {
        return aVar.l(cs);          // 常规 createString
    }
    ByteBuffer bb = sg5.b.get();     // ThreadLocal 暂存
    return aVar.m(v71.f(bb) ?: v71.e());  // 原始字节写
}
```

## `v71` = `ByteBufferBackedCharSequence`（实证）

```java
public interface v71 extends CharSequence {
    charAt/intAccessor → throw UnsupportedOperationException
        ("raw-UTF-8-bytes view for bulk copy; not readable as chars")
    ByteBuffer e();                // 原始 UTF-8 缓冲
    ByteBuffer f(ByteBuffer);      // 拷入暂存缓冲
}
```

- 模型层字符串以**原始 UTF-8 ByteBuffer 视图**持有——
  char 访问全部抛错，仅供整块拷贝。
- `sg5.b` = `ThreadLocal<ByteBuffer>` 暂存缓冲。

## 构建器原语（`com/google/flatbuffers/a.java`）

- `l(CharSequence)` @186 = createString（重编码 UTF-8）。
- `m(ByteBuffer)` @428 = 原始字节串写（不校验不重编）。
- `k(ByteBuffer)` @175 = 缓冲共享族。

## 语义推论

- 收到的字符串字段**不再解码成 char 序列**——以原始
  UTF-8 字节持有，重写时整块拷贝 → **字节精确往返**：
  非法/非常规 UTF-8 也能原样透传。
- 新建字符串走 `l()` 正常编码。

## Harmony 侧

- Harmony 字符串字段重编码 ↔ l() 语义；对**接收到的**
  原始字节须保留 byte 级回写能力（v71 等价）——
  `OriginalFlatBufferTableReader` 的字符串槽 + 编码器
  字符串写须保证字节透传语义（证据性要求）。

## 结论

字符串写路径实名：v71 原始 UTF-8 视图 + m() 块拷贝 =
字节精确往返契约；dbj.c 双路径派发。纯文档+fixture。
