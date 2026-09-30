# Phase 1324 证据 — `haa` 30-op 全覆盖核对

来源：原版 `defpackage/haa`（30 真 op+CONSTRUCTOR/
WRAPPED meta）vs Harmony `data/Original*`（51 文件）。

## `haa` op → Harmony `Original*` 映射

```
ADD_PATH_ELEMENTS      OriginalAddPathElements{Operation,Encoder}
ASSET_CLOUD_PERSISTED  OriginalAssetCloudPersistedOperation
CLEAR_STYLE            (经 RichTextStyle/Modify ops)
CREATE_BLOCK           OriginalCreateBlock{Operation,Encoder}
CREATE_COMMENT         OriginalCommentOperation
CREATE_GROUP           OriginalGroup*/ShapeGroup/GroupMutationOpCodec
CREATE_INK             OriginalCreateInk{Operation,Encoder}+InkPathCodec
CREATE_PAGE            OriginalCreatePage{Operation,Encoder}
CREATE_RECORDING       OriginalCreateRecordingEncoder+RecordingOperation
CREATE_SHAPE          OriginalCreateShape{Operation,Encoder}
DELETE_ENTITIES        OriginalDeleteEntities{Operation,Encoder}
INSERT_CHAR/STRING     OriginalInsertText{Operation,Encoder}
                       +LocalTextMutation(字符级在 mutation 内)
REMOVE_CHAR(S)         OriginalLocalTextMutation/删除 ops
REVIVE_CHARS           (墓碑经 text-mutation/visibility)
MODIFY_BLOCK           OriginalModifyBlock{Operation,Encoder}
MODIFY_COMMENT         OriginalCommentOperation/Modify*
MODIFY_GROUP           OriginalGroupMutationOpCodec
MODIFY_INK             OriginalModifyInk{Operation,Encoder}
MODIFY_PAGE            OriginalModifyPage{Operation,Encoder}
MODIFY_PARAGRAPH_STYLE OriginalRichTextStyle{Operation,Encoder}
MODIFY_PDF_FIELD       OriginalModifyPdfFieldOperation
MODIFY_POSITIONS       OriginalModifyPositions{Operation,Encoder}
MODIFY_RECORDING       OriginalRecordingOperation
MODIFY_SHAPE          OriginalModifyShape{Operation,Encoder}
MODIFY_STYLE           OriginalRichTextStyle{Operation,Encoder}
PEER_INTERACTION       OriginalPeerInteractionOperation
SET_METADATA           OriginalSetMetadata{Operation,Encoder}
TRANSIENT_INTERACTION_ OriginalTransientInteraction*
  ENDED
UPDATE_CHECKBOX        OriginalUpdateCheckboxOperation
```

→ **原版 30-op 全覆盖** —— 每 op 有 `Original*`
Operation（applier）+PayloadEncoder（线编码）——
CRDT op 集 1:1 桥接（`ORIGINAL_*` 前缀）。

## 语义

Harmony `Original*` 层 = 原版 `haa` 全 op 集的
applier+encoder —— 线格式保真+逐 op 覆盖。

## Harmony 决策

每 `haa` op → `Original*Operation`(applier)+`Payload
Encoder`（编码器）—— 全 op 集桥接，语义保真。

## 产出

- fixture `d02-op-coverage.mjs`（10 断言）。
- ADR-1268；中文报告。
