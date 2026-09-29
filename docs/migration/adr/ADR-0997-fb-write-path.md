# ADR-0997 — FlatBuffers 写入路径

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `zwd` = KClass→wx4 serializer 注册表（`z0c(21)` lazy
  map，未知类型 `rgc.b` fail-loud）。
- `com.google.flatbuffers.a` = vendored FlatBufferBuilder：
  `t` prep、`v/w/b/f` 标量、`j` 字段、`k/l` 向量/字符串、
  `r` offset。
- `apb.Z`/`ywd`/`yec` = 结构/表内联序列化器；
  `apb`/`zwd`/`rr2` 助手族分派。

## Harmony 决策

写入经注册表分派；builder API 等价封装；fail-loud 保留。

## Parity 状态

等价。

## 验证

- `d02-fb-write-path.mjs`：11/11 通过。
