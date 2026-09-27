# Phase 880 报告 — cxc 位置层与序列推导

## 范围

登记位置标识 `cxc` 线格式、构造/序列化器与页索引→位置
推导链。纯审计，无源改动。

## 原版发现

- `cxc` 12B 内联结构 `{siteId:u16, pad:u16=0, timestamp:u32,
  index:u32}`（`nti.X` 实证 `prep(4,12)`；`a.s(int)`=零填充）。
- `nti.f` 构造 + `ybg.c` 校验；`nti.g(qo5,i)`=位置锚定到
  创建 op 的 {siteId,opTimestamp}+op 内序号（CRDT 锚）。
- `bfj.b` = 「第 i 个存活元素之后」位置：map 滤已删、
  `fsi.N` 取 list[i-1]（after-anchor；0/越界→null）、
  exc→`ixc.c` cxc。
- `egh.a` = `lxc`（SeqMove）C(1) 单字段包装。
- 使用点：u5j.i 页索引定位、u5j.s moveTo、te0/kp5 op 锚定。

## Harmony 核对

`writeSequence` 12B 布局与 `nti.X` 逐字节相同；
`OriginalSequenceIdentity` 语义一致；after-anchor 语义对应。

## 产出

- 证据：`phase-880-position-layer.md`
- Fixture：`d02-position-layer.mjs`（23/23）
- ADR-0824；全量 Replay 与双 HAP 结果记录于提交。
