# Phase 1130 证据 — e4c.b 完整分派 + `*wc` 应用记录谱系

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `e4c.b(uq9)` 分派全表（`m().ordinal()`）

| ordinal | 载荷 | 记录 |
|---------|------|------|
| 7 | `e46` | `h4c(uwc{len,id,exc,J,tmf,pos})` = 字符插入 |
| 8 | `f46` | `h4c(twc{list,id,exc,J,tmf,pos})` = 串插入 |
| 9 | — | `h4c(vwc{id,exc,J,pos})` = 删除 |
| 10 | — | `h4c(wwc{id,rub,J,pos})` = 范围删 |
| 11 | — | `h4c(xwc{id,g2c,J})` = 复活/恢复 |
| 12,13,14 | — | `f4c(…)` = tombstone 标记 |
| 28 | `mqf` | `f4c(bl2{id,mqf.j(),mqf.l()})` = 删除 op |

## `ywc` = 记录基 `{Integer pos, a()→qo5}`

- `uwc`/`twc` = 插入（len/list + 锚 + 时戳）。
- `vwc` = 单点删 `{id, exc}`。
- `wwc` = 范围删 `{id, List(rub)}`。
- `xwc` = 恢复 `{id, g2c items, pos}`。

## `i4c` = 应用结果 iface

- `h4c` = `{ywc 元素, qo5}` —— 序列元素记录。
- `f4c` = `{bl2 tombstone, qo5}` —— 删除记录。

## `rub extends hvd` / `mqf extends cee`

范围向量适配 / 删除载荷表。

## Harmony 决策

- 文本 op → ordinal 分派 → 记录 `{element|tombstone, id}`；
  恢复 op 携带 item 向量。
- tombstone op（28）直产 bl2 条目。

## 产出

- fixture `d02-apply-records.mjs`（10 断言）。
- ADR-1074；中文报告。
