# Phase 865 报告 — 序列位置标识契约登记

## 范围

登记原版实体位置标识：`cxc` 12 字节结构、`exc.A0` 比较器、
`nti.f/g` 构造、oz9/v09 枚举；核对 Harmony `OriginalSequenceIdentity`
等价层。纯审计阶段，无源改动。

## 原版发现

- `cxc` = {site u16, timestamp u32, index u32} 内联结构，
  `nti.g(opId, index)` 从归属 op 派生位置（wz9 PageImpl 使用点）。
- `exc.A0` 比较器三级排序：ts 升序（Java int 回绕减法）→
  site 升序（u16）→ **index 倒序**——倒序 tie-break 是移植陷阱。
- `oz9` = {UNBOOKMARKED, BOOKMARKED}；`v09` = {ANIMATION, INK,
  SHAPE, BLOCK}。

## Harmony 核对

`OperationIdentity.ets` 的 `OriginalSequenceIdentity` +
`compareOriginalSequenceIdentity` 已逐项等价（含 `toJavaInt`
回绕与 index 倒序），注释即引 `exc.A0`。赢家行物化覆盖 oz9
语义；实体状态表覆盖 v09 四类。

## 产出

- 证据：`phase-865-sequence-position-identity.md`
- Fixture：`d02-sequence-position-identity.mjs`（24/24）
- ADR-0809；全量 Replay 与双 HAP 结果记录于提交。
