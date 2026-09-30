# Phase 1153 证据 — bs1 bundle 头 + l96 IO 门面

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `bs1{short a, int b, AtomicInteger c}` = bundle 头

```java
bs1(int capacity, short version)
  a = version            // schema/格式版本
  b = capacity           // 容量/op 上限
  c = new AtomicInteger(capacity)   // 原子计数器
```

`{version:short, capacity:int, counter:AtomicInteger}` —
线模 bundle 的头部：格式版本 + 容量 + 活 op 原子计数
（`a`/`c` 的 `core.model` bundle 头字段）。

## `l96.M(short s) = new bs1(0, s)`

bundle 头工厂 —— `core.model.a` ctor 用它产 `{0,version}`
头。

## `l96` = IO 门面

`M0(InputStream)→byte[]` = 流→字节（8KB 缓冲
`ByteArrayOutputStream` + `i0` copy）；`l96` 是 IO/字节
工具门面（同 `au1` 集合门面、`xj2` 杂项门面族）。

## 语义

bundle 头 = `{version, capacity, AtomicInteger}` ——
序列化 note/page 的格式版本 + op 计数；`AtomicInteger`
为并发 op 累加/校验。

## Harmony 决策

- bundle 头 = `{version:u16, capacity:u32, counter}`；
  `l96` = IO 工具（stream→bytes）。
- Harmony：原子计数用 `Atomics` 或串行 int。

## 产出

- fixture `d02-bs1-head.mjs`（10 断言）。
- ADR-1097；中文报告。
