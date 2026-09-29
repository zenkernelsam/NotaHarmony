# ADR-0931 — `zae` 统一视图层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `zae` = 5 方法接口（a=x63 格式、b=schemaVersion、
  c=原始 ByteBuffer、d=迭代器、e=物化列表）。
- 三 root 映射：`uae(r29)→I`、`yae(vt9)→J`、
  `uae(zgb)→K`；物化分派 `lv2.T/U/V`。
- **`c()` 直返源 ByteBuffer**——defer 写字节直通
  （零重编码，byte-exact）。
- `tae`/`xae` = 共享-holder 迭代器（next() 重 init 同一
  uq9，调用方不得保留引用）；remove() 抛
  UnsupportedOperationException。
- `lv2.U/V` = vt9/zgb 物化器；`lv2.W` = s83 墓碑物化。

## Harmony 决策

等价：视图抽象 + 源 buffer 直通 + 共享-holder 语义
（Harmony 侧可物化为不可变数组）。

## Parity 状态

等价。

## 验证

- `d02-zae-view-layer.mjs`：17/17 通过。
