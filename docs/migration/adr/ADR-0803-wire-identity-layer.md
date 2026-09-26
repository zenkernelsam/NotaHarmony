# ADR-0803 — 线协议身份层登记（haa/uq9/qo5/r29/utf）

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- `haa`：32 项 payload-type byte 枚举（NONE=0 … MODIFY_COMMENT=31），
  `nz3` 越界回退 NONE。
- `uq9` Op 信封（7 字段）：id@0（required `qo5`）、clientTime@1 u64、
  serverTime@2 u64 可空、audioTime@3 u64 可空、payloadType@4（haa）、
  payload@5 间接表、transientInteraction@6（`sdf`）可空。
- `qo5` Id：site short + timestamp int → 8 字节复合。
- `r29` NoteBundle 根表（8 字段）：noteId@0（utf UUID）、legacyNoteId@1、
  editorSite@2、editorUserId@3、createdAt@4、creatorUserId@5、
  ops@6（uq9 向量）、schemaVersion@7。
- `utf` Uuid：`xwd` 内联结构基座，bitsLow/bitsHigh 双 long = 16 字节。

## Harmony 决策

- `parseOriginalOperationEnvelope` / `OriginalNoteBundlePageIdentity`
  与原版字段编号逐一相同（id@0、clientTime@1、serverTime@2、
  audioTime@3、payloadType@4、payload@5；noteId@0-16B、editorSite@2、
  ops@6、schemaVersion@7）。
- 31 个 `ORIGINAL_*_PAYLOAD_TYPE` 常量与 haa 逐值一致；
  `payloadTypeKnown` 门对应 nz3 的 NONE 回退语义（未知值不崩、
  标记 unknown）。
- serverTime 非空为同步路径附加门（原版 `parseSynced` 语义）。

## Parity 状态

- 等价：判别枚举、Op 信封、Id、NoteBundle、UUID 布局全部逐字段对齐；
  唯一偏差为 Harmony 的显式上界与 required 门（更严 fail-closed）。
- transientInteraction@6（sdf）已登记为可空副信道，Harmony 以
  `OriginalTransientInteraction*` 编码器处理同语义。

## 验证

- `d02-wire-identity-layer.mjs`：41/41 通过（含 31 值枚举全量映射核对）。
- 全量 Replay 与双 HAP 构建见 Phase 859 报告/提交。
