# ADR-0977 — manifest 条目 handler 分类

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `yz implements Appendable`{StringBuilder,List} =
  manifest 写器；`a00 implements CharSequence`{List} =
  条目集；`zz`{Object,int}=条目。
- `wz` iface → `gnd`{xoe,long} 目录 + `ug7`
  abstract{cye,cqe} → `tg7`/`sg7`{String,cqe} 资产。
- `yz.e/b/a/c` 四类条目写入。

## Harmony 决策

handler 分类保留；yz Appendable→StringBuilder 等价。

## Parity 状态

等价。

## 验证

- `d02-manifest-handlers.mjs`：10/10 通过。
