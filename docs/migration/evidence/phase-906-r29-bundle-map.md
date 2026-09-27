# Phase 906 证据 — `r29` NoteBundle accessor→偏移全图

## 目的

钉死线上根表的读契约（905 uq9 同法）。
`decompiled_1.0.3` + Harmony 解析器对照。

## `r29` accessor 全图（c(4+2i) 实证）

| 访问器 | `c(N)` | 字段 | 类型 | 语义 |
|--------|--------|------|------|------|
| `o()` | c(4) | **f0** | `utf` 16B 内联 | **noteId** |
| `n()` | c(6) | **f1** | `utf` 16B 内联 | **legacyNoteId** |
| `l()` | c(8) | **f2** | `getShort` | **editorSite** |
| `m()` | c(10) | **f3** | String | **editorUserId** |
| `j()` | c(12) | **f4** | `getLong` | **createdAt** |
| `k()` | c(14) | **f5** | String | **creatorUserId** |
| `p()`/`r(uq9,i)` | c(16) | **f6** | int 数 + `uq9` 向量 | **ops** |
| `q()` | c(18) | **f7** | `getShort` | **schemaVersion** |

## Harmony 对照（`decodeOriginalNoteBundle` 实证）

| 原版字段 | Harmony 读法 | 对齐 |
|----------|--------------|------|
| f0 noteId | `readInlineBytes(0,16)` 必填 | ✓ |
| f1 legacyNoteId | 存在但引导不需取值 | ✓ |
| f2 editorSite | `readUint16(2,0)` | ✓ |
| f3 editorUserId | `validateByteVector(3)` | ✓ |
| f4 createdAt | 存在但不取 | ✓ |
| f5 creatorUserId | `validateByteVector(5)` | ✓ |
| f6 ops | `hasField(6)` 必填 + `readTableVector` | ✓ |
| f7 schemaVersion | `readUint16(7,0)` | ✓ |

## 已知分歧（fail-closed 有意差异）

- 原版 `uq9.m()`：payloadType 越界 → **NONE 回退**
  （live 模型宽容）。
- Harmony 引导解析：`payloadType<1 || >MAX` → **throw**
  ——引导重放宁可拒绝不错放（fail-closed 语义一致）。

## 结论

NoteBundle 八字段 accessor/偏移全实名；Harmony 引导
解析逐字段对齐；payloadType 严格度差异已记录为
fail-closed 有意分歧。纯文档+fixture 阶段。
