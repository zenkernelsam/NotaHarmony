# Phase 860 证据 — zq9 表↔类型权威注册表与 Op 信封写入器

## 目的

859 登记了 `haa` 判别枚举与 `uq9` Op 信封读取侧。本阶段登记
`zq9`（操作表类 ↔ payload-type 的权威映射 + Op 信封写入器），
并与 Harmony 编码器/常量做交叉核对。

## 原版证据（`decompiled_1.0.3/sources/defpackage/zq9.java`）

### 权威映射（static init，`mx7` map，31 条）

| 表类 | haa 类型 | 值 |
|------|----------|----|
| l2d | SET_METADATA | 1 |
| ra0 | ASSET_CLOUD_PERSISTED | 2 |
| ln2 | CREATE_PAGE | 3 |
| ge8 | MODIFY_PAGE | 4 |
| yn2 | CREATE_RECORDING | 5 |
| ke8 | MODIFY_RECORDING | 6 |
| e46 | INSERT_CHAR | 7 |
| f46 | INSERT_STRING | 8 |
| pub | REMOVE_CHAR | 9 |
| qub | REMOVE_CHARS | 10 |
| f2c | REVIVE_CHARS | 11 |
| me8 | MODIFY_STYLE | 12 |
| he8 | MODIFY_PARAGRAPH_STYLE | 13 |
| io1 | CLEAR_STYLE | 14 |
| dm2 | CREATE_INK | 15 |
| gd | ADD_PATH_ELEMENTS | 16 |
| wd8 | MODIFY_INK | 17 |
| ao2 | CREATE_SHAPE | 18 |
| le8 | MODIFY_SHAPE | 19 |
| cm2 | CREATE_GROUP | 20 |
| vd8 | MODIFY_GROUP | 21 |
| rl2 | CREATE_BLOCK | 22 |
| td8 | MODIFY_BLOCK | 23 |
| je8 | MODIFY_POSITIONS | 24 |
| s83 | DELETE_ENTITIES | 25 |
| tdf | TRANSIENT_INTERACTION_ENDED | 26 |
| ee8 | MODIFY_PDF_FIELD | 27 |
| mqf | UPDATE_CHECKBOX | 28 |
| yda | PEER_INTERACTION | 29 |
| tl2 | CREATE_COMMENT | 30 |
| ud8 | MODIFY_COMMENT | 31 |

未映射类经 `b()` 走 `rgc.b` 抛异常 —— fail-closed 未知类型拒绝。

### Op 信封写入器 `zq9.e`

```
aVar.C(7);                    // startTable(7) — uq9 七字段
aVar.j(0, rh8.O(qo5Var,aVar));// id@0（qo5 内联 8 字节写入）
aVar.f(1, j);                 // clientTime@1 u64
aVar.f(2, tmf.I)  // serverTime@2（非空时）
aVar.f(3, tmf.I)  // audioTime@3（非空时）
aVar.c(4, haa.I, 0);          // payloadType@4 byte（默认 0=NONE）
aVar.h(5, iA);                // payload@5 间接表（ree.a 先行写入）
aVar.h(6, num)   // transientInteraction@6（sdf 存在时）
int iN = aVar.n();
aVar.z(iN, 4);                // required 标记 → field 0（id）
aVar.z(iN, 14);               // required 标记 → field 5（payload）
```

**payload 恒为 required**——NONE 判别仅是未映射类的防御哨兵，
线上 Op 必载有效负载表。

### transientInteraction（`sdf` 表，uq9 field 6 副信道）

`sdf` = TransientInteraction{interactionId@0（qo5 可空）、timeout@1
（int→`mmf`）} — 操作上的瞬态标记，**不同于** type-26 的
`tdf`（TransientInteractionEnded 负载本体）。

## Harmony 侧

- 31 个 `ORIGINAL_*_PAYLOAD_TYPE` 常量与上表逐值一致（859 fixture 已全量
  断言）；各 `Original*Operation`/`Applier` 经 `supports(payloadType)` 分发。
- `parseOriginalOperationEnvelope` 的「type≠0 必须有 payload」门 ↔
  原版 required(5)；`requireField id@0` ↔ required(0)。
- `OriginalTransientInteractionPayloadEncoder` 编码 type-26 的
  `{interactionId, replacedByOp}` 八字节恒等双槽 — 对应 `tdf`
  （ENDED 负载），与 `sdf` 副信道字段不同物。

## 结论

zq9 权威映射闭卷：31 条表↔类型全部恢复并与 Harmony 常量/分发逐一
对齐；Op 写入器的 required(0)/required(5) 语义已在 Harmony 解码门
中对应。`sdf` 副信道登记为可空标记表，与 type-26 负载区分。
本阶段纯文档+fixture，无源改动。
