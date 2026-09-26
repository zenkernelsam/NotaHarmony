# ADR-0809 — 序列位置标识契约（cxc/exc/nti + oz9/v09）

## 状态

accepted（文档+fixture，无源改动；Harmony 侧先前已等价移植）

## 原版契约（`decompiled_1.0.3`）

- `cxc`：12 字节 xwd 内联结构 = {site u16@0, pad@2, timestamp u32@4,
  index u32@8}；`nti.f` 以 `t(4,12)` flatbuffer 结构构造并经
  `ybg.c` ka4 校验；`nti.g(opId, index)` 从归属 op 派生实体位置。
- `exc.A0` 比较器：timestamp 升序（Java int 减法，可回绕）→
  site 升序（u16）→ **index 降序**（`other.C() - C()`，刻意倒序）。
- `oz9` = {UNBOOKMARKED=0, BOOKMARKED=1}（bookmark 寄存器取值）；
  `v09` = {ANIMATION, INK, SHAPE, BLOCK}（实体种类）。

## Harmony 决策

`OriginalSequenceIdentity`{ts,siteId,index} + `seq:ts:site:index`
编码 + `compareOriginalSequenceIdentity`（`toJavaInt` 保留 u32→i32
回绕、index 项 `right-left` 倒序与原版逐项一致）+
`encodeOriginalPageStorageId` 页面主键。oz9 语义由 bookmarkWinner
持久化行覆盖；v09 四类由实体状态表/编码器覆盖。

## Parity 状态

等价（比较器含两个易错点均已正确移植：Java 回绕、倒序 tie-break）。

## 验证

- `d02-sequence-position-identity.mjs`：24/24 通过。
- 全量 Replay 与双 HAP 构建见 Phase 865 提交。
