# Phase 1117 证据 — v71 字节漏斗 CharSequence + uq9 op 访问器

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `v71 extends CharSequence` = ByteBufferBackedCharSequence

```java
length()/charAt()/subSequence() → throw
  "raw-UTF-8-bytes view for bulk copy; not readable as chars"
ByteBuffer e();          // 取内部 buffer
ByteBuffer f(ByteBuffer); // 灌进给定 buffer
```

纯字节 funnel —— CharSequence 接口只为兼容 createString 签名，
实际只暴露 `e()/f(bb)` 字节通道。**禁止逐字符读**。

## `uq9 extends cee implements ka4` = op 表访问器

- `l()→qo5` = opId（`p(qo5)` 绑读）。
- `m()→haa` = op 类型。
- `j()→tmf` = transient seq；`k()→long` = 时戳。
- equals = `m()` + `l()` + transient `sdfVar.j()` 比较。
- hashCode = `(l().hashCode + m().hashCode*31)*31 + transientHash`。

## `sg5.b` = `ThreadLocal<ByteBuffer>` scratch

`dbj.c`/`kci.j` 共用 —— 零拷贝通道的线程本地 buffer。

## Harmony 决策

- 字节串字段以 ArrayBuffer 视图表征，禁逐字符读；
  序列化时直灌 builder buffer。
- op 等值 = {type, id, transient} 三键。

## 产出

- fixture `d02-byte-funnel.mjs`（10 断言）。
- ADR-1061；中文报告。
