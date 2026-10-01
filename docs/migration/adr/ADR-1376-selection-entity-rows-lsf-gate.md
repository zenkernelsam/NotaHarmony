# ADR-1376: 选择菜单实体专属行按原版 urf 收为 lsf 专属；已锁单元素仅 UNLOCK

- 状态：已接受
- 日期：2026-08-09
- 关联：ADR-1374（DESELECT isf 门）、ADR-1375（urf 行序 + f() 门）

## 背景

Phase 1439/1440 已将 `DESELECT` 与 `SEND_*` 收为选区种类感知，但
`CROP`/`EDIT_MATH`/`FLIP_H`/`FLIP_V` 仍按"选中元素的类型/基数"开放。
1.4.2 `urf` 装配器显示这些行全部经 `hv6VarP1` 推导，而 `hv6VarP1`
仅在 `msfVar instanceof lsf`（单元素点选）时非空。

## 决策

1. `selectionCanFlip`/`selectionCanCrop`/`selectionCanEditMath` 均以
   `!supportsDeselectMode` 前置（lsf/jsf 才可达；jsf 另被 groupIds 排除）。
2. `canFlipImageSelection` 收紧为恰一图（`hv6VarP1 instanceof l97` 单实体）。
3. 新增 `selectionLockedOnly` 镜像 + overlay `lockedOnly` prop：
   旗开语义下点选已锁单元素 → 菜单仅 `UNLOCK` 一行（`xqf(oag.x2(Y),∅)`）。

## 理由与后果

- 基数不可区分 isf-单元素与 lsf——必须沿用 `supportsDeselectMode`
  来源标记（ADR-1374 架构）。
- 原版旗态：`h35.I`=POSITION_LOCKED `td5` 灰度旗、defaults 无键、
  生产缺省 false。按 ADR-1438 系（textOnly）先例，已移植特性按旗开
  语义实现并登记旗门；生产旗关时多出的 UNLOCK 单行属"旗开行为"，
  不构成默认行为回归。
- 正向：isf 单元素选区菜单从 8+ 行收敛到原版口径；多图集合不再误显 FLIP。
- 风险：lsf 语义在 Harmony 由 `!supportsDeselectMode` 近似（实际含 jsf），
  但 jsf 的 `groupIds>0` 天然被各门排除，无额外分支需求。

## 验证

`d02-selection-entity-rows-lsf-gate.mjs` 15/15；全量基线 + 双 HAP 见报告。
