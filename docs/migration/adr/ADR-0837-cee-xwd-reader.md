# ADR-0837 — `cee`/`xwd` 读侧基类原语实名

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `cee` = 生成代码 Table 基类：`I`=bb_pos、`J`=ByteBuffer、
  `K`=vtable 起点（`i−getInt(i)`）、`L`=vtable 长度；
  `b(i)`=间接偏移、`c(i)`=vtable 槽查（`4+2·字段号`）、
  `d`=__assign、`e`=__string（UTF-8 长前缀+zq6 解码器）。
- `xwd` = Struct 基类：`I/J` 两字段内联定位（无 vtable）。
- `c(4+2i)` 读公式与写侧 `z(off,4+2i)` required 标记
  **双向一致**——wire 层读写原语全闭合。

## Harmony 决策

`OriginalFlatBufferTableReader` vtable 槽查/间接偏移/
字符串解码逐方法对齐；内联结构读对齐 xwd.b。

## Parity 状态

等价（读侧原语逐方法实名，读写公式互证）。

## 验证

- `d02-cee-xwd-reader.mjs`：16/16 通过。
- 全量 Replay 766 文件绿，见 Phase 893 提交。
