# ADR-1252：Op 分类法分歧

## 状态

已接受（Phase 1308）。

## 决策

Harmony op 模型 = `ORIGINAL_*` 桥接原版 `haa` op +
本地元素级超集；粒度（元素 vs 字符）与 undo-as-op
为记录性差异 —— 非 1:1，语义差异需文档化。

## 理由

原版 `haa` 32-op 是字符粒度协作 CRDT（INSERT_CHAR/
REMOVE_CHARS/REVIVE_CHARS 墓碑）且 `UNDO`/`REDO`
是本地栈非同步 op；Harmony `OpTypes` = `ORIGINAL_*`
桥接 + 元素级超集（INSERT_ELEMENTS/ERASE_*/
GROUP_ELEMENTS/UNDO/REDO/PAGE_*/UPDATE_NOTE_*）
—— CRDT 粒度与 undo 语义不同。

## 后果

Harmony 用元素级 op+ORIGINAL_ 桥接，与原版字符级
CRDT 在粒度/undo/tombstone 上有差异 —— 记录差异，
不声称逐 op 等价；后续需确认与原版同步互操作性。
