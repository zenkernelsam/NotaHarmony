# Phase 1308 证据 — Op 分类法分歧（Harmony vs 原版 `haa`）

来源：`core/model/OpTypes.ets` vs 原版 `defpackage/haa`
（32-op，Phase 1275）。

## 原版 `haa` 32-op

`SET_METADATA`/`CREATE_PAGE`/`CREATE_RECORDING`/
`INSERT_CHAR`/`INSERT_STRING`/`REMOVE_CHAR`/
`REMOVE_CHARS`/`REVIVE_CHARS`/`MODIFY_STYLE`/
`MODIFY_PARAGRAPH_STYLE`/`CREATE_INK`/`CREATE_SHAPE`/
`CREATE_GROUP`/`CREATE_BLOCK`/`DELETE_ENTITIES`/
`MODIFY_PDF_FIELD`/`UPDATE_CHECKBOX`/`CREATE_COMMENT`/
`MODIFY_COMMENT`/… —— 协作 CRDT op（含墓碑
`REVIVE_CHARS`、字符粒度 `INSERT_CHAR`/`REMOVE_CHARS`）。

## Harmony `core/model/OpTypes`

**双轨**：
```
ORIGINAL_*  —— 镜像原版 haa（ORIGINAL_CREATE_PAGE/
              INSERT_TEXT/MODIFY_TEXT_STYLE/CREATE_INK/
              SET_METADATA/PARTIAL_ERASE/TEXT_VISIBILITY/
              HANDWRITING_CONVERSION/CLIPBOARD_PASTE/…）
本地超集    —— 原版没有：UNDO/REDO（同步 op！）、
              ERASE_PARTIAL/ERASE_WHOLE、GROUP_ELEMENTS、
              REORDER_PAGES、PAGE_SNAPSHOT、PAGE_BATCH、
              PAGE_BOOKMARK、DUPLICATE_PAGE、DELETE_PAGE
              _COMPENSATION、UPDATE_NOTE_*、PUSH、
              INSERT_ELEMENTS/REMOVE_ELEMENTS/REPLACE_
              ELEMENTS/REORDER_ELEMENTS/TRANSFORM_ELEMENTS
```

## 语义分歧

- 原版 `UNDO`/`REDO` 是本地撤销栈（`nnf`/`dve`），
  **不是**同步 op；Harmony 将其编码为 op —— 语义
  迁移差异。
- 原版 op 是字符粒度（INSERT_CHAR/REMOVE_CHARS/
  REVIVE_CHARS 墓碑）；Harmony 是元素/文本粒度
  （INSERT_ELEMENTS/REMOVE_TEXT）—— CRDT 模型
  粒度不同。
- `ORIGINAL_*` 前缀 = 原版 op 的导入/桥接标记。

## Harmony 决策

Harmony op 模型 = `ORIGINAL_*` 桥接原版 op + 本地
元素级超集 —— 与 `haa` 非 1:1；需 ADR 记录粒度与
undo-as-op 差异。

## 产出

- fixture `d02-op-taxonomy.mjs`（10 断言）。
- ADR-1252；中文报告。
