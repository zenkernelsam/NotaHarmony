# ADR-1379: sqf 分发侧审计收口——urf 菜单轴终局

- 状态：已接受
- 日期：2026-08-09
- 关联：ADR-1374/1375/1376（装配侧）、ADR-1377（四项裁决）、ADR-0586（LOCK 合并）

## 决策

1.4.2 `sqf`（wqf.ordinal() 23-case 分发器）与 Harmony
`onSelectionMenuAction` 逐支对照完毕：所有移植项语义一致，
所有 fail-closed/死项（CONVERT_*/STICKER/FIT_TO_PAGE）维持缺省。
**不新增代码**——审计结果固化于证据文档与回归 fixture。

关键对齐确认：原版动作后 `omeVar.a()`/`H.a()`=清选区（hmb.g(null)），
Harmony FLIP/GROUP/UNGROUP/DELETE/LOCK/COPY 均已对应清选区；
DESELECT→deselectMode+快照、EDIT_MATH→gv9+H() 面板态、
MORE→frf.b 展开位（平铺适配）逐一核对。

## 后果

urf/wqf 选择菜单轴（装配 23 项 + 分发 23 case）至此**双向收口**。
后续选择轴工作移出菜单，转向手势/变换等其它子轴。

## 验证

`d02-selection-menu-dispatch-closure.mjs` 11/11；基线+构建见提交。
