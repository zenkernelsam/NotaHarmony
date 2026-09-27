# Phase 929 证据 — `lxc` SeqMove + `th7` + 尾类分流

## 目的

lxc 布局钉死 + 列表实现类实名 + 非线型类分流。

## `lxc` = `SeqMove{toId:cxc@0(c4)}`

单字段 move-to-position 载荷——ge8.moveTo 与
879 注册的 `{toId}` 一致：页面/元素移动以
**目标位置 ID** 表达（CRDT 序内锚定，非索引）。

## `th7` = `u4` 子类（RandomAccess + Serializable）

- `public Object[] I; int J; boolean K` ——
  **Object[] 支撑的可变 List**（Kotlin
  AbstractMutableList 族）。
- `m18.S()` 返回 th7、`m18.E(th7)` 冻结为不可变
  ——lv2 物化器的 builder/结果两相即此类。
- toString 中 `th7 th7Var` 即物化后的 List 引用。

## 非线型分流

- `ume` = `Attached{alwaysMinimize,minimizedAlignment,
  expandedAlignment}` —— Android BottomSheet UI 状态
  类，与 .note 线型无关。
- `m15`/`o15`（`lv2.K/L` 签名，`m15.l(o15)` 谓词）——
  序列化上下文族（`m15 extends p15`），非载荷表。

## Harmony 核对

SeqMove 单字段编码对齐；物化 List 语义对齐
（已 immutable）。

## 结论

lxc 钉死 + th7 builder 实名；ume/m15/o15 分流为非
线型类——线层引用图彻底无遗漏。
