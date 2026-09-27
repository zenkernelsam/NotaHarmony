# Phase 882 证据 — op 事务层（fsi.s/vt9/bs1/rh8/rgc/qwc/f8d）

## 目的

登记 op 创建管线的收口：事务入口、OpsBundle 根表、
op-id 计数器与 CRDT 树节点（`decompiled_1.0.3`）。

## `fsi.s(bs1, bs1, long, ix4)` = 事务入口

1. 建 builder `a` + `ArrayList`；`ix4.invoke(new xq9(bs1Var2,
   bs1Var, list, a, j))`——以捕获了双计数器+列表+builder+
   clientTime 的 xq9 调用用户 lambda（lambda 内逐 op
   `xq9.a(wq9)`）。
2. `au1.S1(list)` → int[] uq9 索引 → `aVar.D(4,len,4)` 建向量
   （逆序写入）。
3. `aVar.C(2)` 2 字段根：`h(0, iO)`=ops 向量、`i(1, rgc.a)`
   =schemaVersion short → `aVar.z(iN,4)` + `p(iN)` 收尾。
4. 包 `vt9` → `lv2.U(vt9)` 物化 List<uq9> 返回。

`fsi.t(bs1,bs1,j,List)` = 变体：预建 wq9 列表经 `pq1` 包装
λ→s（`m18.l0(new wq9(...))` 单 op 形态，见 kzc/lzc）。

## `vt9` = `OpsBundle`（toString 实证）

`OpsBundle(ops=lv2.U(this), schemaVersion=ymf.a(k()))`：
`j()`=ops 向量长、`k()`=ymf 包装 schemaVersion short、
`l(uq9,i)`=元素访问器。`lv2.U` = 向量物化器。

## `rgc.a` = schemaVersion 常量

`ar6.K.I`——`ar6` = schema 版本枚举（成员如
`BLOCKS_AND_SHAPES_POSITION_LOCK=7`，命名特性版本）；
`K` = `new ar6(15)` = **当前线协议 schema v15**。

## `bs1` = op-id 计数器

`{a:short site, b:int baseCounter, c:AtomicInteger}`——
`tzc.P`/`tzc.Q` 为会话级双实例（瞬态/持久）；`rh8.b(int,
short)` = `qo5{counter,site}` 构造器。

## `qwc`/`f8d` = CRDT 树节点

`f8d` = `SharedNodeData`（toString：rawSiteId:a、
rawTimestamp:b、rawAudioTime:c、parent:d、children? list）；
`qwc{f8d, int}` = 版本化节点；`qwc.c` = 哨兵根
（`f8d{qo5(0,-1).c/.d, 0L, null, []}`）。

## 调用面

- `tzc`（编辑会话）：`fsi.s(P,Q,currentTimeMillis,λ)` 批量
  事务、`fsi.t` 单 op 形式（`u5j.i(x09,i,0,14)` = 全默认
  建页——掩码 14 默认 pageIndex/pageCount/省略参数3）。
- `n1d`：`xj2.A(..., ns(tzc, fsi.s 结果, map, eof, λ), 3)`——
  事务结果进入同步派发。

## Harmony 侧

- `OpStoreImpl` op 追加 + `nextOperationTimestamp` ↔
  bs1/rh8.b 序号分配；ops 向量+schema 字段 ↔ Harmony
  bundle 编码；`xq9 transaction` 注释已存。
- SharedNodeData/CRDT 树 ↔ 物化态+winner 寄存器层（864/866）。

## 结论

op 写管线全链闭合：u5j→wq9→xq9→fsi.s→vt9 OpsBundle
{ops,schemaV=15}→lv2.U；bs1 双计数器与 qwc/f8d 树节点
实名。纯文档+fixture 阶段。
