# Phase 857 证据 — u5j 操作工厂与 ka4 校验契约登记

## 目的

Harmony 编码器长期引用 `u5j.*`（u5j.q/r/x/y/n/s 等）。本阶段登记 `u5j.java`
这一原版**操作负载工厂**全貌，以及每个操作表附着的 `ka4` 校验接口契约。

## u5j 工厂注册表（`decompiled_1.0.3/sources/defpackage/u5j.java`，1274 行）

`public static` 工厂方法 → FlatBuffer 表类型（25 个方法 → 20 个表类型）：

| 方法 | 返回 | 对应 Harmony 操作 |
|------|------|------|
| q/r | `wd8`（19 字段） | MODIFY_INK（多目标修改 + 带渲染寄存器变体） |
| n | `td8`（18 字段） | MODIFY_BLOCK |
| x/y | `le8`（17 字段） | MODIFY_SHAPE（两变体：移动/样式） |
| s/t | `ge8` | MODIFY_PAGE（书签/背景经 oz9 ModifyPage） |
| u | `he8`，v | `je8`，w | `ke8` | GROUP/DELETE/SET_METADATA 族 |
| z/A | `me8` | CREATE 族复合负载 |
| D/E/F | `pub`/`qub`/`cee` | 页面结构/创建操作 |
| G/H/J | `f2c`/`l2d`/`mqf` | 块/形状/录制创建 |
| a/f/g | `gd`/`rl2`/`dm2` | 删除/文本/变换 |
| i/j | `ln2`/`ao2` | 位置修改/元素插入 |
| k/l | `s83` | 文本样式（k 为 l 的 defaults 重载） |
| p | `vd8`，C | `Object` | 位置/杂项 |

## ka4 校验接口（同版 `defpackage`）

- **82 个类实现 `ka4`**：所有操作表 + 子对象（u5j 返回类型全部在列：
  ge8/he8/je8/ke8/me8/vd8/wd8/td8/le8/cee/qub/pub/f2c/l2d/mqf/gd/rl2/dm2/
  ln2/ao2/s83 + 实体/几何子表 sw9/nz9/m2d/lxc 等）。
- `ka4.a()` 返回 **错误字符串或 null** — 每操作/子对象一个 fail-closed
  校验门，写入前执行。
- 全文 124 个 `return "..."` 字面量，其中 **33 条为校验错误消息**
  （`Cannot/Must/Invalid/Should/No` 前缀），其余为 toString 调试串
  （`Name(field=` 形态）。
- 代表性契约：`Cannot modify the same target twice in one payload`、
  `Cannot create 0 pages`、`Cannot insert empty string`、
  `Must specify more than 0 inks/...members/...pages`、
  `Cannot provide math properties for a non-Math Block`、
  `Cannot provide paper for a non-Text Block`、
  `Cannot set background to a pdf which consumes a different number of pages
  than pages modified`。

## Harmony 侧

- `data/` 编码器在**同一边界**执行 fail-closed 校验：编码即抛 `Error`，
  共 **31 条 `original <OP> ...` 门**（如 MODIFY_INK 的 target 计数 /
  render-register / style / color / width / 重复目标六道门 ↔ 原版
  `Cannot modify the same target twice in one payload` 等）。
- 语义差异：原版返回错误字符串（收集式）、Harmony 首错即抛（fail-fast）
  — 同为拒绝非法负载，无漏门缺口。
- `BinaryOpCodec` 另有 8 条预算/溢出/magic 门，对应原版 ByteBuffer 边界。

## 结论

操作工厂层登记完毕：u5j 25 方法→20 表类型已全数映射；ka4 为 82 实现的
写入前校验契约（33 条错误消息），Harmony 以编码器 throw-gate 形式等价
覆盖同一边界。本阶段纯文档+fixture，无源改动。
