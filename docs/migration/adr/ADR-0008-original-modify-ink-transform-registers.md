# ADR-0008：原版 MODIFY_INK nullable transform register 与缺席 winner

- 状态：Accepted（rotation/scale 受证明子集；page/origin 由 ADR-0009 扩展）
- 日期：2026-08-10
- 关联：D-02、数据库 v30、ADR-0006、ADR-0007

## 背景

原版 `wd8` field 3 rotation 是 `k2d(SetFloat)`，field 4 scale 是 `y2d(SetSize)`。外层 setter 缺席表示不修改；setter 存在但
内部 value 缺席表示显式写入 null。`rz1.P/Q` 对后一种情况仍调用 `fqb.c(op,value=null)`，因此 clear 也必须推进独立 winner。
`s06.j()/b()` 在 winning value 为 null 时回退到 CREATE_INK 的 rotation/scale，而不是回退到 0 或单位缩放。

进一步直读 `xj2.k()` 发现：没有持久化 register 时，它用 CREATE 值建立读取默认值，但 `fqb.a`（winner）保持 null。故首个 MODIFY
无条件获胜；ADR-0006/0007 和 v28/v29 曾把 CREATE identity 当初始 winner，会错误拒绝来自另一 site、op ID 较小但首次写入的合法操作。

## 决策

数据库升至 v30：

1. center path、style、color、width 增加 `*_winner_present`。v29 迁移时，仅当旧 winner 不等于目标 Ink identity 才标记真实 winner；
   相等身份不可能来自另一条 MODIFY，故可无损识别旧占位。
2. 保存 CREATE 的 origin/rotation/scale 五个基线分量。新 CREATE 直接写入；旧 v29 行首次 transform 修改时从保留的原始
   CREATE_INK envelope 恢复，缺失、解析失败或当前矩阵分歧则整批 DEFERRED。
3. rotation 与 scale 分别保存 nullable value、winner identity 和 winner-presence。value null 且 winner 存在表示显式 clear；
   winner 缺席表示从未修改，两者视觉上都回退 CREATE，但后续乱序判定不同。

`OriginalModifyInkOperationApplier` 开放 field 3/4/5/6/7/8 的任意组合。rotation/scale 先独立判定 winning 子集，再由 CREATE origin、
最终 rotation 与最终 scale 重建完整矩阵和 bounds；不从现有矩阵反解分量。多 Ink 仍先全部验证后写入，同页只推进一次 revision。

## 后果与验证

- 首个 transform/render/path MODIFY 即使 op ID 小于 CREATE 也会获胜；真实 winner 建立后恢复严格 unsigned `(timestamp,site)` LWW。
- rotation clear、scale clear 会保存自己的 winner，并准确回到各 Ink 的 CREATE 值。
- `d02-modify-ink-transform.mjs` 覆盖真实 nullable setter、v29→v30、四个旧 register 的缺席 winner 恢复、较小 ID 首写、
  rotation/scale 独立乱序、显式 clear、CREATE fallback、多 Ink 原子性、故障回滚和无本地日志。
- 本 ADR 落地时 page/origin、z-index、辅助路径、Pencil/Tape/effects 与后续内容 payload 仍未完成；page/origin 后续由
  ADR-0009 闭环。未执行设备 Hypium，不据此关闭完整 MODIFY_INK 或 D-02。
