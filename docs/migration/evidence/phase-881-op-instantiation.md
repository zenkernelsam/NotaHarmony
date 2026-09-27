# Phase 881 证据 — `wq9`/`xq9` op 实例化层

## 目的

登记原版 op 创建/应用调用链：`xq9Var.a(new wq9(payload,...))`
（te0/kp5/nx6/zm7/eca 等 47 处）——`decompiled_1.0.3`。
JADX 报 wq9/xq9 为 `classes2.dex`（非混淆实名保留）。

## `wq9` = `OpCreationMetadata`（toString 实证）

`OpCreationMetadata(payload=cee, transient=b,
_inProgressTransientId=qo5, transientTimeout=null, audioTime=xgb)`：

- Kotlin 默认参数存根：`(cee, qo5?, z, xgb?, int mask)`——
  `&2`→inProgressTransientId=null、`&4`→transient=false、
  `&16`→audioTime=null。
- **省略参数序号 3 = `transientTimeout`**（toString 遗留其名；
  `&8` 分支被 JADX 省略，同 haj.a 模式——调用方掩码 30 =
  bit1+2+3+4 四项全默认）。
- 自动 transient 判定：`z || inProgressTransientId!=null ||
  payloadType ∈ {26,29}`（`zq9.b(cee).ordinal()` switch）——
  26/29 = transient-interaction 相关 payload 类型。
- 调用形态：`wq9(payload, null, false, null, 30)`——显式三参
  + 全默认掩码 30。

## `xq9` = op 实例化 lambda（合成类）

捕获 `{bs1 瞬态计数器, bs1 持久计数器, ArrayList op 索引,
builder d, long clientTime}`；`a(wq9)` 流程：

1. **双计数器**：非瞬态（`wq9.e` 置位）时先
   `bs1.c.getAndUpdate(bs1Var2.c.get()-1)` 同步持久计数；
   瞬态用第二计数器——transient 与 persistent 分占序号空间。
2. `qo5 = rh8.b(counter.getAndIncrement(), site)`——分配下一个
   op-id（`rh8.b(counter, site)` = qo5{site,counter} 构造器）。
3. transient 时构造 `sdf` TransientInteraction：C(2) 表，
   field0 = inProgressTransientId（缺省 = 新 op 自身 id），
   `rh8.O(qo5,builder)` 序列化 + `ybg.c` 校验。
4. `zq9.e(builder, qo5, payload, clientTime, null,
   tmf(audioTime)?, sdf?)` → uq9 op 信封；表索引入
   ArrayList（ops 向量累积）。
5. 返回新 op-id `qo5`。

## 辅助原语

- `rh8.b(int counter, site)`：qo5 op-id 构造。
- `rh8.O(qo5, builder)`：qo5 序列化器。
- `zq9.e(...)`：uq9 信封编码（860 登记 7 字段）。

## Harmony 侧

- `OpStoreImpl`/`nextOperationTimestamp` = op 序号分配对应；
  `StrokePersistence` 注释已引 `xq9 transaction` 语义。
- `sdf` TransientInteraction ↔ `OriginalPeerInteractionOperation`
  transient 面；`zq9.e` 七字段信封 ↔ Harmony op 编码器。
- 瞬态/持久双序号空间 → Harmony 以 op timestamp/siteId
  分配等价表达。

## 结论

op 创建调用链实名登记：`wq9` 元数据 + `xq9` 分配 lambda +
双序号空间 + sdf 瞬态包装 + zq9.e 信封。纯文档+fixture 阶段。
