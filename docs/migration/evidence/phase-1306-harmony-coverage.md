# Phase 1306 证据 — Harmony 实现覆盖核对

来源：`note/src/main/ets/`（291 ETS 文件 + 4 Ability）。

## Harmony 结构 vs 原版

```
noteability/NoteAbility        — 主入口 ≈ MainActivity
notebackupability/             — 备份 ≈ 备份/导出
noteformability/               — Form 卡片 ≈ AppWidget
  pages/{FolderNotesCard,NewNoteCard,NewRecordingCard,
         FolderNotesEditPage}   ≈ widgets×5
noteformeditability/           — 卡片编辑
core/{adaptation,algorithm,model,op}/   — 核心（77）
data/  (157)                   — 数据层
rendering/  (22)               — 渲染
ui/{components,editor,library,settings,theme}/ (31)
```

## 数据层 CRDT 已实现

`data/` 含 **op codec + 同步**：
```
BinaryOpCodec, OperationCompaction, OperationIdentity,
DeferredSyncedOperationBundle, IncomingOperationSync
Coordinator, {DeletePage,DuplicatePage}OpCodec, OpStore,
BackupBatch{Applier,Publisher,Restorer}, AssetRepository
Impl, AsyncMutex, ...
```

→ CRDT op 编解码/压实/入站同步协调/资产/备份 —
— 原版 `haa` 32-op + `ops/synced` 的 Harmony 实现。

## 编辑器

`ui/editor/`：`ArkUIStylusAdapter`（触控笔）、`Note
CanvasView`、`NotePage`、`NoteZoomView`、`PageManager
Bar`、`PageOverviewPanel`、`EditorToolbar` —— 笔记
编辑器（笔/缩放/页管理）。

## 语义

Harmony 端已具备 **CRDT 同步+编辑器+卡片+备份** 主体
—— 原版架构的 Harmony 对应物基本就位。

## 产出

- fixture `d02-harmony-coverage.mjs`（10 断言）。
- ADR-1250；中文报告。
