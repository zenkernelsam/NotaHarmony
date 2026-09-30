# Phase 1310 证据 — Harmony `.note` 导入（iOS ZIP+plist）

来源：`data/{NoteImporter,ZipArchive,ImportIdentity,
NotabilitySessionParser,BinaryPlistParser}.ets` + `ui/
components/ImportDetailsSheet.ets`。

## 导入管线（`.note` = iOS ZIP bundle）

```
NoteImporter: fileIo/picker → ZipReader(.note ZIP)
  → Session.plist(加密检测 hasFailedSuffix/encrypted)
  → parseManifest/parsePackagedRecordings/parsePage/
    parsePageElement
  → pdfService/image/media 资产解码
  → manifest.noteId|generateId → noteIdExists(导入为副本)
  → DatabaseManager 落库
```

## 保真细节（对照原版）

- `jv5` 内容 URI 上限 flag16（pdf/ntb 打开路径）= **500MB**。
- `%PDF-` magic 类型嗅探（对应原版 `nj3` 注册表）。
- `qc`「Add Files」序位第一；`.note`/Office 未映射类型
  过滤（`yq8.d/e` 未反编译语义不透明 → fail-closed）。
- `recordings.json` → 同步 `CREATE_RECORDING` op。
- `.note` 顶层目录以笔记名命名（`OP-AMP/Session.plist`）。

## `NotabilitySessionParser` = iOS binary plist 解析

`GLKeyedArchiver` `$top`/`$0` + `bplist00` + 小端
IEEE-754 + `InkedSpatialHash` 形状识别层 —— iOS
`.note`/Session.plist 格式解析。

## 语义

Harmony 导入 = **iOS `.note` ZIP+plist**（非 Android
`.ntb` FlatBuffers）—— 双格式中实现 `.note`；`.ntb`
为未覆盖路径（或经同步 ops）。

## Harmony 决策

`.note` 导入已实现（ZIP+plist+magic+加密检测+副本导入）
—— 与原版导入语义对齐；`.ntb` 导入为待办/经同步。

## 产出

- fixture `d02-note-import.mjs`（10 断言）。
- ADR-1254；中文报告。
