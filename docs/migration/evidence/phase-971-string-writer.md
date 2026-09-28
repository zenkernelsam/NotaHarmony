# Phase 971 — `dbj.c` 字符串写器双路径 + `v71` UTF-8 零拷贝

来源：`decompiled_1.0.3/sources/defpackage/dbj.java`、
`v71.java`、`com/google/flatbuffers/a.java`

## 1. `dbj.c(CharSequence, a)` — 两路字符串序列化

```java
if (!(cs instanceof v71))
    return aVar.l(charSequence);              // 常规: builder UTF-8 编码
ByteBuffer bb = (ByteBuffer) sg5.b.get();     // ThreadLocal 池化缓冲
return aVar.m(bb != null ? ((v71)cs).f(bb)
                        : ((v71)cs).e());     // v71: 原始 UTF-8 字节直通
```

- 常规路：`a.l` = createString——ASCII 快扫 +
  逐字符 UTF-8 长度计算 + `zq6`（`this.n`）编码器写入。
- `v71` 路：`sg5.b` ThreadLocal ByteBuffer →
  `f(bb)` 写入原始 UTF-8 字节 → `a.m(bb)` =
  createByteVector（`b(0)` 终止符 + `D(1,len,1)` +
  `put(bb)` + `o()`）。

## 2. `v71` = ByteBufferBackedCharSequence

接口：`e()`/`f(ByteBuffer)` 返 UTF-8 ByteBuffer；
`subSequence` 抛 `UnsupportedOperationException`：
*"ByteBufferBackedCharSequence is a raw-UTF-8-bytes
view for bulk copy; not readable as chars"*。

**语义**：原生端持有的字符串（如 PDF 文本/资产名）
已是 UTF-8 字节——写时零拷贝直通，避免 decode→
re-encode 往返。`sg5.b` = STRING_BUFFER_HOLDER
（Phase 944 命名）。

## 3. `a.m` = createByteVector 细节

`b(0)` NUL 终止 → `D(1,remaining,1)` → `put(bb)` →
`o()`——向量带 NUL（FlatBuffers 字符串规范）。

## 4. Harmony 对齐

Harmony 字符串字段走 encodeUTF8 单路——`v71` 直通
优化为性能细节，语义等价（UTF-8+NUL+长度前缀）。

## 5. 验证

`d02-string-writer.mjs` 静态断言。
