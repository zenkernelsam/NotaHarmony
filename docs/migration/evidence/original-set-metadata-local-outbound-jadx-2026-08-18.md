# 原版 SET_METADATA 六项本地出站与原子写入证据（2026-08-18）

## 1. 证据范围与只读基准

本阶段只研究原版 1.0.3 的 `SET_METADATA` 六项 note-level register 如何从当前状态重新构造成
`l2d` FlatBuffer，以及 Harmony 本地写入应如何保持 field presence、Float32 canonicalization 和事务边界。
Desktop 目录只作只读证据源；本阶段没有在 Desktop 建立或修改鸿蒙源码工作树。

原版文件位于：
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

关键源码（SHA-256 已由本阶段读取的同一文件计算并核对）：

| 文件 | SHA-256 | 关键位置 | 证明 |
|---|---|---:|---|
| `xj2.java` | `1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C` | 168-207 | `K()` 建立 8-field table；field 0～2 为 wrapper，field 3～7 为 scalar/string/enum；boolean/layout/wrap 强制写 presence |
| `xj2.java` | `1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C` | 700-736 | `d(...)` 的 nullable 参数与 FlatBuffer 构造入口 |
| `l2d.java` | `59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8` | 16-52 | 六项 accessor/value validation；font size、family、language 约束 |
| `l2d.java` | `59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8` | 84-165 | field 2～7 的 vtable field number 与 nullable accessor |
| `rz1.java` | `99B3433644F2BDCFC139EB96FDEEB120F7A87A5BDA693D066DE905116B9E2A86` | 246-274 | handwriting wrapper 存在时无条件写 nullable inner value；普通字段按对象 presence 写入 |
| `u5j.java` | `F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC` | 366-380 | 快照/重建链从寄存器重新调用 `xj2.d(...)` |
| `a79.java` | `FE5C7C5FBA990B53DD3296E96953CA37F9D8D309CA15509F2F78634EA4B14E13` | 59-152 | 六项作为 NoteImpl 持久寄存器状态保存 |

## 2. wire 结论

`xj2.K()` 的实际字段映射如下：

| field | 类型 | 本地 writer 规则 |
|---:|---|---|
| 0 | title wrapper | 本阶段明确缺席，避免设置偏好时重置 title |
| 1 | pageBackground wrapper | 本阶段明确缺席，避免设置偏好时重置纸张 |
| 2 | handwriting `z2d` wrapper | `has=true,value=null` 写 present wrapper + absent inner string；`has=false` 才是不 patch |
| 3 | align boolean | `has=true` 即写入，即使值为 `false` |
| 4 | default font family string | `has=true` 写 UTF-8 string；空字符串是合法 concrete value（仍受 30 UTF-16 单元约束） |
| 5 | default font size Float32 | `has=true` 写 little-endian Float32；readback 以 Float32 canonical value 为准 |
| 6 | layout enum byte | `has=true` 即写入 `0(PAGED)`，不能把 0 当作缺席 |
| 7 | block-wrap enum byte | `has=true` 即写入 `0(WRAP_ENABLED)`，不能把 0 当作缺席 |

生产 `encodeOriginalSetMetadataFields()` 采用 root vtable `[0,0,4,8,12,16,20,21]`，root object size
24；此处 0/1 永远为零，field 2 的 nested wrapper 与原版 `z2d` 形状一致。字符串以 UTF-8 round-trip
和有界 byte budget 校验，防止恶意 payload 造成无界分配。

## 3. 原子本地写入证据

`note/src/main/ets/data/OriginalNoteMetadataPersistence.ets` 的顺序固定为：

1. 校验 patch 并先编码/解码自己的 payload，得到 wire canonical value；
2. 读取六个 winner 的 coherent snapshot，拒绝无有效变化的 no-op；
3. 在调用者已持有的 SQLite transaction 中分配 operation identity；
4. 用生产 `OriginalSetMetadataOperationApplier` 应用独立 LWW winner；
5. readback 六个寄存器，验证请求字段已 canonicalize、未请求字段完全不变；
6. 验证 `structure_revision` 恰好加一并更新 `note_meta.updated_at`；
7. append `OpType.ORIGINAL_SET_METADATA`，`uploadImmediately=true`。

该文件不自行 `beginTransaction/commit/rollBack`，由
`NoteRepositoryImpl.updateOriginalNoteMetadata()` 在 `libraryMetadataMutationMutex` 下统一拥有事务。
任何 reducer/readback/append 异常都会由 repository rollback，不能留下半个 winner、孤立 revision 或未配套的
`operation_log` 行。

## 4. Replay 与 fixture 交叉核对

- `docs/migration/replays/d02-original-set-metadata-local-outbound.mjs`：读取原版源码、检查生产源码顺序，
  独立重建 concrete/explicit-null/false-zero FlatBuffer，并以 SQLite model 验证 commit/rollback/no-op gate。
- `note/src/test/OriginalSetMetadataPayloadEncoder.test.ets`：覆盖六字段 concrete、handwriting explicit null、
  false/0 forced presence、title/background omission、invalid language/family/size/enum。
- `note/src/main/ets/data/OriginalSetMetadataOperation.ets`：既有入站 decoder/reducer 是本阶段 writer 的 readback
  oracle；本地 writer 不另造第二套寄存器语义。

## 5. 明确未闭环项

本证据只支持“六项 local outbound + wire + reducer persistence + atomic operation-log append”这一个边界，不能据此
宣称：

- PAGELESS 页面/缩略图 consumer 已接线；
- align-to-lines、handwriting recognition provider、default-font inheritance 或 block-wrap consumer 已等价；
- 六项已有 Harmony Undo/Redo history codec；
- 真实设备、旧库升级、多设备同步、`NOTE_BUNDLE` round-trip 或 UI 像素体验已验收。

上述项目继续列为后续审计缺口。
