# ADR-0137：Note 导出精确字节视图

## 状态

Accepted - Phase 160，2026-08-12

## 背景

`NoteExporter.exportToFile()` 将 `Uint8Array.buffer` 直接交给 `fileIo.writeSync`。当数组是更大底层 buffer 的带偏移视图时，写入可能包含视图外字节，导致临时 `.note` 文件尾部污染或长度不一致。

## 决策

- 所有导出文件写入都通过 `exactArrayBuffer()`，按 `byteOffset` 到 `byteOffset + byteLength` 复制精确范围。
- 不改变 ZIP 内容、导出事务、picker 流程或备份批次数据。
- 这是 Harmony 文件 I/O 视图边界修复，不涉及原版 Android 导出实现差异。

