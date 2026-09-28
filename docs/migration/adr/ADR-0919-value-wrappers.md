# ADR-0919 — 值类包装与 jmf/ix4 接口

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `mmf`/`tmf`/`cmf` = int/long/byte 值类包装
  （Comparable）——线型位宽载体（ZIndex=long 等）。
- `jmf` = ByteList 接口 `{size, byteAt, iterator}`；
  `nl8` 可变、`hd`/`xd8` 冻结（`w71` 标记）。
  `ys2.O` 三 jmf 参 = 三条编码路径字节向量——
  927 字节路径编码的写侧闭环。
- `ix4 extends xx4` = invoke() Function1 提供器——
  向量写器懒物化抽象。

## Harmony 决策

值类 → 原生位宽字段；jmf → Uint8Array；ix4 为实现
细节无需对应物。

## Parity 状态

等价。

## 验证

- `d02-value-wrappers.mjs`：11/11 通过。
