# Phase 893 报告 — 读侧基类 `cee`/`xwd` 实名

## 范围

实名全部 reader 依赖的读侧原语（与 892 写侧对称）。
纯审计，无源改动。

## 原版发现

- `cee` = 生成 Table 基类：I/J/K/L 四状态（bb_pos/
  ByteBuffer/vtable 起点/vtable 长度）；b=间接偏移、
  c(i)=vtable 槽查、d=__assign、e=__string（zq6 UTF-8）。
- `xwd` = Struct 基类：I/J 内联定位，无 vtable。
- `c(4+2·字段号)` 读公式 = 写侧 required `z(off,4+2i)`
  双向一致——892 公式在读侧实证。

## Harmony 核对

reader vtable 槽查/间接偏移/字符串解码逐方法对应；
内联结构读对齐。

## 产出

- 证据：`phase-893-cee-xwd-reader.md`
- Fixture：`d02-cee-xwd-reader.mjs`（16/16）
- ADR-0837；全量 Replay 766 文件绿。
