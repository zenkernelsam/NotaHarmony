# ADR-1029：集合 spec 布局 + nr5 布局引擎

## 状态

已接受（Phase 1085）。

## 决策

- `m4c` 13 字段 spec（margins/纵横/子项/细节）+ `l4c` 布局
  持有 `{mha, nr5, double}`。
- `nr5 extends mxc` = 布局引擎 iface（`a(mr5)` relayout +
  `builder()→or5`）；缺省 `qr5.a`。

## 依据

`m4c` ctor + `l4c`/`nr5`/`bxc` 结构。

## 后果

Harmony 排版引擎经 `nr5` 抽象；集合 spec 布局参数原样。
