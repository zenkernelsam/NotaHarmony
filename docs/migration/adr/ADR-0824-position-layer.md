# ADR-0824 — cxc 位置层与序列推导

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `cxc` = 12B 内联结构 `{siteId:u16@0, pad:u16=0@2,
  timestamp:u32@4, index:u32@8}`（`nti.X` 实证：`prep(4,12)`
  + int+int+pad2+short；`a.s(int)` 为零填充）。
- `nti.f(site,timestamp,index)` 构造 + `ybg.c` 校验；
  `nti.g(qo5,i)` = `f(qo5.c,qo5.d,i)`——位置锚定到创建 op
  的 {siteId,opTimestamp}+op 内序号（CRDT 锚）。
- `bfj.b(svb,i,map)` = 「第 i 个存活元素之后」的位置：
  map 过滤已删项、`fsi.N` 取 list[i-1]（after-anchor；
  0/越界→null）、`swc.d(hr5)` exc→`ixc.c` cxc。
- `egh.a(cxc)` = `lxc`（SeqMove）C(1) 单字段包装。

## Harmony 决策

`writeSequence` 等写出 `{siteId,0,timestamp,index}` 12B
——与 `nti.X` 逐字节相同；`OriginalSequenceIdentity` 与
`nti.g` 语义一致（865 比较器已对齐）。

## Parity 状态

等价（线格式与语义双层逐字节/逐项对齐）。

## 验证

- `d02-position-layer.mjs`：23/23 通过。
- 全量 Replay 与双 HAP 构建见 Phase 880 提交。
