# Phase 993 — `z5c.x` apply 侧载荷分派 + `uq9.q/r` 访问器 + `aq1`

来源：`decompiled_1.0.3/sources/defpackage/{z5c,uq9,aq1}.java`

## 1. `z5c.x(uq9)` = 序数→载荷类物化器（32 case 全表）

```java
switch (uq9.m().ordinal()):
  0  → rgc.b(...) + throw   // NONE = fail-loud
  1  l2d SetMetadata        17 wd8 ModifyInk
  2  ra0 AssetCloudPersisted 18 ao2 CreateShape
  3  ln2 CreatePage         19 le8 ModifyShape
  4  ge8 ModifyPage         20 cm2 CreateGroup
  5  yn2 CreateRecording    21 vd8 ModifyGroup
  6  ke8 ModifyRecording    22 rl2 CreateBlock
  7  e46 InsertChar         23 td8 ModifyBlock
  8  f46 InsertString       24 je8 ModifyPositions
  9  pub RemoveChar         25 s83 DeleteEntities
  10 qub RemoveChars        26 tdf TransientEnded
  11 f2c ReviveChars        27 ee8 ModifyPdfField
  12 me8 ModifyStyle        28 mqf UpdateCheckbox
  13 he8 ModifyParaStyle    29 yda PeerInteraction
  14 io1 ClearStyle         30 tl2 CreateComment
  15 dm2 CreateInk          31 ud8 ModifyComment
  16 gd AddPathElements
default → o14.t()
new T() → uq9.q(holder) → return holder
```

↔ Phase 964 `zq9.a`（class→haa 反向表）完全对偶。

## 2. `uq9` 访问器（信封字段 = cee 槽位）

| 方法 | vtable 槽 | 字段 | 语义 |
|------|-----------|------|------|
| `q(cee)` | 14 | f5 payload | `cee.d(bb.getInt+base)` |
| `r(sdf)` | 16 | f6 transientInteraction | 0→null else init+return |
| toString | — | — | `Op(id, clientTime, serverTime, audioTime, payload, transientInteraction)` |

toString 实证官方字段名（与 Phase 964 写序一致）。

## 3. `aq1` = ClientOp 行实体

`{uq9 a(可空), qo5 b(opId), long c(length)}`——
`ft0` 读径 `LENGTH(op)<=?` 超限时 blob=null 但保留
opId+length（大 op 按需重取/分流）。

## 4. `gk4` 补全（接 Phase 981）

`m(long)` = `(int)(j>>32),(short)j → rh8.b` = qo5 解包；
`o(byte[])` = 8B long 数组→qo5 列表解码器
（packed opId 列）。

## 5. Harmony 对齐

等价：序数分派表 + NONE fail-loud + payload 槽位
直读 + 行实体三段。

## 6. 验证

`d02-apply-dispatcher.mjs` 静态断言。
