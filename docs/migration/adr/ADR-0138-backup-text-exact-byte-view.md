# ADR-0138：系统备份文本精确字节视图

## 状态

Accepted - Phase 161，2026-08-12

## 背景

`NoteBackupAbility.writeText()` 直接把 `TextEncoder.encodeInto(value).buffer` 传给文件 API。为了保证系统备份快照/manifest 只写有效 UTF-8 字节，不能依赖 TypedArray 底层 buffer 恰好紧密排列。

## 决策

- 先保存 `Uint8Array`，再按 `byteOffset` 与 `byteLength` 切出精确 `ArrayBuffer`。
- 不改变备份目录结构、文件名、JSON 内容或恢复流程。

