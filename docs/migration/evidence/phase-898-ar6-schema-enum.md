# Phase 898 证据 — `ar6` schema 版本里程碑枚举

## 目的

实名 schema-version 枚举全里程碑（`vt9` 字段1 +
`rgc.a` 当前值的类型）。`decompiled_1.0.3`。

## `ar6` = SchemaVersion short 枚举（16 值实证）

| 值 | 里程碑 | 语义 |
|----|--------|------|
| 0 | `PRE_SHIPPING` | 发布前 |
| 1 | `ALPHA_1` | Alpha 1 |
| 2 | `LAYOUT_MODE` | 布局模式引入 |
| 3 | `CHECKBOX_OP` | 复选框 op（type 29 族） |
| 4 | `SHAPES_FORCE` | 形状强制 |
| 5 | `TEXTBOX_MARGINS_AND_RESIZING_TO_FIT_TEXT` | 文本框边距+自适应 |
| 6 | `DECORATOR_STYLE` | 装饰样式 |
| 7 | `BLOCKS_AND_SHAPES_POSITION_LOCK` | 块/形状位置锁 |
| 8 | `PEER_INTERACTION` | 协作交互（type 27/28 族） |
| 9 | `TAPE_PATTERN` | 胶带图案 |
| 10 | `WRITING_DIRECTION` | 书写方向 |
| 11 | `CODE_AND_CALLIGRAPHY` | 代码/书法样式 |
| 12 | `COMMENTS` | 评论（type 31 族） |
| 13 | `MODIFY_INK_TAPE_PATTERN` | 墨迹胶带图案修改 |
| 14 | `BLOCK_WRAP_SUPPORT` | 块环绕支持（a79 寄存器） |
| 15 | `INK_EFFECT` | 墨迹效果 = **当前值 K** |

- `ar6.K = new ar6(15)` = 当前 schema；`rgc.a`（882）
  写进 vt9.schemaVersion = 15。
- `ymf`（897 UShort）是线上包装，`ar6` 是语义枚举。
- `zq6 J = new zq6(0)` = values 数组持有器。

## 语义推论

每 op/feature 有最低 schema 门（新 op 类型只能写进
≥对应里程碑的文档）；版本号 = 功能兼容下限，
保留历史文档可读性。

## Harmony 侧

- Harmony ops-bundle 写 schema=15 ↔ ar6.K；
- 功能门（评论/胶带图案/书法等）↔ 对应里程碑值
  条件启用——须与原版本序一致避免低版本误开。

## 结论

schema 里程碑全 16 值实名；当前 15=INK_EFFECT；
功能-版本映射表建立。纯文档+fixture 阶段。
