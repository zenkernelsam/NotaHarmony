# ADR-0987 — FlatBuffers Table/Struct 基类与 32 操作类型全集

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `cee` = FlatBuffers **Table** 基类：`{I pos, J bb, K vtable-off,
  L vtable-len}`，`b()`=uoffset 间接，`c()`=vtable 槽（越界 0），
  `e()`=内联 UTF-8 解码；`xwd` = **Struct** 基类（固定布局）。
- `haa` = **32 操作类型全集**（byte 0–31，NONE→MODIFY_COMMENT），
  `I`=wire 码，`nz3`=EnumEntries。
- `exc.A0` = pageId 三键排序：a1 → (m&0xffff) → C。

## Harmony 决策

- OpType 枚举对齐 32 值 byte 码；Table/Struct 双读模型保留；
  pageId 排序保持三键字典序（m 无符号）。

## Parity 状态

等价。

## 验证

- `d02-flatbuffers-op-taxonomy.mjs`：12/12 通过。
