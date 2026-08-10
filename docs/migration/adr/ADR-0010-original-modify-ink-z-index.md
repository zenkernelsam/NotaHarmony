# ADR-0010：原版 MODIFY_INK z-index 独立 register 与页面层序重排

- 状态：Accepted（Ink z-index 受证明子集）
- 日期：2026-08-10
- 关联：D-02、数据库 v32、ADR-0004、ADR-0009

## 背景

原版 `wd8.A()` 从 FlatBuffer offset `c(30)` 读取 64-bit field 13。`q06.c()` 把它包装为按 unsigned long 比较的
`xgb`，再通过 `rz1.R(..., zIndexRegister, ...)` 独立参加 LWW；字段缺席时不修改。`fi0.d()` 对共享实体变换也使用同一个
register 契约。

CREATE 侧 `q06` 构造器先取已持久化的 `d16.n`，否则取 `dm2.B()` 的显式 z-index，再回退外层 `uq9.k()` client time；
`xj2.k(null, fallback)` 只提供当前值，不建立 winner。因此 CREATE identity 不能冒充初始 winner，否则较小 op ID 的第一个合法
MODIFY 会被错误拒绝。页面物化顺序由 `vnd.c/compareTo` 证明为 unsigned z-index，再按元素 `qo5` identity 排序。

## 决策

数据库升至 v32，在 `original_ink_state` 中分开保存 `create_z_index`、winning `z_index_value`、winner identity 和
winner-presence。新 CREATE 直接保存 fallback 且 winner 缺席；旧 v31 行首次 winning z-index 修改时，从保留的 CREATE_INK
envelope 恢复 fallback，并要求它与 `original_element_z_index` 当前值一致。

`OriginalModifyInkOperationApplier` 开放 field 13，并遵循：

1. z-index 使用 canonical uint64 decimal，不能经过 JavaScript `number`；最大值 `18446744073709551615` 必须无损。
2. field 13 与 page/origin、rotation、scale 及渲染字段分别拥有 winner；同 payload 可原子组合。
3. winning 修改先核对 register fallback/value、页面归属、实际 snapshot/归档成员和完整原版层序，再执行任何写入。
4. 同页修改 CAS 更新 z-index 并按 `(uint64 zIndex, uint32 timestamp, uint16 site)` 重排；跨页修改同时搬运 Stroke、更新
   page assignment 与 z-index，并重排源/目标页。
5. 每个受影响页面只推进一次 content revision 并失效 Ink 搜索；远端操作不写本地 operation log 或 Undo。
6. winner、物化 z-index、页面 revision 或层序任一分歧均由 inbox 外层事务整体回滚，不以数组尾部或本地连续 z 值修补。

## 后果与验证

- 较小 op ID 的首次修改获胜；winner 建立后严格按 unsigned `(timestamp,site)` 拒绝旧操作。
- 支持同页、live/archive 与 page/origin+z-index 组合，多 Ink 在首次写入前完成全量预检。
- `d02-modify-ink-z-index.mjs` 覆盖真实 field 13、uint64 最大值、v31→v32、首写、乱序、同页/跨页/归档排序、
  多 Ink 原子性、层序分歧、迁移/应用回滚和无本地日志。
- custom/fill path、fill color/style map、nib、Pencil/Tape/effects 与后续内容 payload 仍未完成；未执行设备 Hypium，
  不据此关闭完整 MODIFY_INK 或 D-02。
