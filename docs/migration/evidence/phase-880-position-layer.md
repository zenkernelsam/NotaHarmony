# Phase 880 证据 — cxc 位置层与序列推导（nti/bfj/egh/fsi）

## 目的

登记位置标识 `cxc` 的线格式、构造/序列化器与「页索引→
位置」推导链（`decompiled_1.0.3/sources/defpackage/`）。

## `cxc` 内联结构（`nti.X`/`nti.f` 实证）

`nti.X`：`aVar.t(4,12)` = FlatBuffers `prep(4字节对齐,12字节)`；
`w(iC)`、`w(iD)` 各 4B int；`s(2)` = **`pad(2)` 写两字节 0**
（`a.s(int)` 实证循环写 0）；`y(sC)` 2B short。

内存布局（builder 逆序→正序）：`{sC:u16@0, 0:u16@2,
iD:u32@4, iC:u32@8}` = **`cxc{siteId:u16, pad:u16=0,
timestamp:u32, index:u32}` 12 字节**。

- `cxc.c()=siteId`、`d()=timestamp`、`C()=index`。
- `nti.f(short s,int i,int i2)` = 构造器：同 12B 布局 +
  `ybg.c` 校验。
- `nti.g(qo5, int i)` = `f(qo5.c(), qo5.d(), i)`——**位置 =
  创建 op 的 {siteId, opTimestamp} + op 内子序号 i**
  （CRDT 锚定：每个位置归到生成它的 op + 元素序号）。

## 推导链

- `bfj.b(svb, int i, Map)`：「第 i 个存活元素之后」的位置。
  `svb` = 序列模型（`getOrder()→jxc→i()` 得 `swc` 列表）；
  `map` 非空时先滤除 `map.get(swc.getValue())==TRUE` 的已删
  项；`fsi.N(i, list)` 取第 i-1 元素；`swc.d(hr5)` 得 exc
  位置 → `ixc.c` 包成 cxc；空列表/越界返回 null（=首插）。
- `fsi.N(i, list)`：`list.get(i-1)`；i=0→null（插到开头）；
  负→`Cannot insert at a negative index` + null；越界→
  `Unable to find location` + null。**after-anchor 语义**。
- `egh.a(cxc)`：构造 `lxc`（SeqMove）C(1) 表单字段
  `j(0, nti.X(cxc))`——moveTo 目标线形式。
- `ixc.c(exc)`：exc 位置实现→cxc 包装。

## 使用点

- `u5j.i`：`bfj.b(f1a.b, 页索引, f1a.h)` → ln2 location。
- `u5j.s`：Integer 页索引 → `bfj.b` → `egh.a` → lxc。
- `te0/kp5`：`nti.g(op.qo5, 0)` → 新实体元素位置。
- `wz9.q/nti`：富文本/实体位置派生。

## Harmony 侧（逐字节等价）

`OriginalInsertTextPayloadEncoder.writeSequence` 等：
`{siteId:u16@0, 0:u16@2, timestamp:u32@4, index:u32@8}` 12B
——与 `nti.X` 布局**逐字节相同**（pad=0 吻合 `s(2)` 零填）。
`OriginalSequenceIdentity{timestamp,siteId,index}` 与
`nti.g` 的 {qo5.c,qo5.d,i} 语义一致（865 比较器已对齐）。
`insertAfter`-式定位与 `fsi.N` after-anchor 语义对应。

## 结论

cxc 12B 结构、nti.f/g/X 构造序列化、bfj.b 删除感知定位、
fsi.N after-anchor、egh.a SeqMove 包装全部实证；Harmony
线格式逐字节等价。纯文档+fixture 阶段。
