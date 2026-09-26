# Phase 859 证据 — 线协议身份层登记（haa 判别式 / uq9 Op 信封 / qo5 Id / r29 NoteBundle / utf Uuid）

## 目的

856–858 登记了写入器、校验、读取基座与传输信封。本阶段登记**操作本身
的线协议身份层**：payload-type 判别枚举、Op 信封字段、操作 ID 结构、
NoteBundle 根表与内联 UUID —— 并逐字段核对 Harmony 解码实现。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### `haa` — payload-type 判别枚举（uq9 field 4）

32 项 byte 枚举，`nz3` 查表、越界回退 NONE：

```
NONE=0, SET_METADATA=1, ASSET_CLOUD_PERSISTED=2, CREATE_PAGE=3,
MODIFY_PAGE=4, CREATE_RECORDING=5, MODIFY_RECORDING=6,
INSERT_CHAR=7, INSERT_STRING=8, REMOVE_CHAR=9, REMOVE_CHARS=10,
REVIVE_CHARS=11, MODIFY_STYLE=12, MODIFY_PARAGRAPH_STYLE=13,
CLEAR_STYLE=14, CREATE_INK=15, ADD_PATH_ELEMENTS=16, MODIFY_INK=17,
CREATE_SHAPE=18, MODIFY_SHAPE=19, CREATE_GROUP=20, MODIFY_GROUP=21,
CREATE_BLOCK=22, MODIFY_BLOCK=23, MODIFY_POSITIONS=24,
DELETE_ENTITIES=25, TRANSIENT_INTERACTION_ENDED=26, MODIFY_PDF_FIELD=27,
UPDATE_CHECKBOX=28, PEER_INTERACTION=29, CREATE_COMMENT=30,
MODIFY_COMMENT=31
```

### `uq9` — Op 信封（cee 表，7 字段）

vtable `c(n)` → 字段 `(n-4)/2`：

| 字段 | 访问器 | 类型 | 说明 |
|------|--------|------|------|
| 0 | `p()` | `qo5` 表（required） | `o14.i("No value for (required) field id")` |
| 1 | `k()` | u64 | clientTime |
| 2 | `n()` | u64→`tmf` | serverTime（可空） |
| 3 | `j()` | u64→`tmf` | audioTime（可空） |
| 4 | `m()` | byte→`haa` | payloadType |
| 5 | `q(cee)` | 间接表 | payload（操作表本体） |
| 6 | `r()` | `sdf` 表 | transientInteraction（可空） |

### `qo5` — Op Id（site/timestamp 复合）

`c()` short = site、`d()` int = timestamp；toString `Id(site=, timestamp=)`。
== 8 字节内联布局：siteId u16 + timestamp u32。

### `r29` — NoteBundle 根表（cee 表，8 字段）

| 字段 | 访问器 | 类型 | 说明 |
|------|--------|------|------|
| 0 | `o()` | `utf` | noteId（16 字节内联 UUID） |
| 1 | `n()` | `utf` | legacyNoteId（可空） |
| 2 | `l()` | short | editorSite |
| 3 | `m()` | string | editorUserId |
| 4 | `j()` | long | createdAt |
| 5 | `k()` | string | creatorUserId |
| 6 | `p()`/`T()` | `uq9` 向量 | ops |
| 7 | `q()` | short | schemaVersion |

### `utf` — Uuid 内联结构（`xwd` 结构基座，非 cee 表）

`d()` = bitsLow（getLong@I+0）、`c()` = bitsHigh（getLong@I+8）—
16 字节无 vtable 内联结构。

## Harmony 侧（`note/src/main/ets/data`）

- `OriginalSyncedOperationFlatBuffer.ets`：
  - `ORIGINAL_PAYLOAD_TYPE_MIN=1` / `MAX=31` ↔ haa 全域（NONE=0 排除）；
  - `parseOriginalOperationEnvelope`：id@0（requireField 8 字节：
    siteId u16 + timestamp u32 ↔ qo5）、clientTime@1 u64decimal、
    serverTime@2、audioTime@3、payloadType@4 u8、payload@5 间接表 +
    越界/缺载门 — **字段编号与 uq9 逐一相同**；
  - `parseOriginalSyncedOperationEnvelope` 追加 serverTime 非空门
    （同步操作必有服务端时间戳）。
- `OriginalNoteBundlePageIdentity.ets`：NoteBundle 根读取 —
  noteId@0（16 字节内联 UUID ↔ utf）、editorSiteId@2 u16、ops@6 向量、
  schemaVersion@7 u16 — **与 r29 字段逐一相同**。
- 31 个 `ORIGINAL_*_PAYLOAD_TYPE` 常量值与 haa 完全一致
  （CREATE_INK=15 … MODIFY_COMMENT=31），UPDATE_CHECKBOX=28 与
  TRANSIENT_INTERACTION_ENDED=26 在应用器分发中使用。

## 结论

线协议身份层逐字段核对一致：haa 32 判别值、uq9 七字段 Op 信封、
qo5 八字节 Id、r29 八字段 NoteBundle、utf 16 字节 UUID 全部与
Harmony 解码实现对齐。瞬态交互（sdf）作为 field 6 可空副信道登记。
本阶段纯文档+fixture，无源改动。
