# ADR-1254：`.note` 导入

## 状态

已接受（Phase 1310）。

## 决策

Harmony 导入 = iOS `.note` ZIP+binary-plist（已实现，
对照 `jv5`/`qc`/`yq8` 原版语义）；`.ntb` Android 格式
经同步 ops 或后续 Phase —— 导入语义对齐。

## 理由

`NoteImporter`（`.note` ZIP→`Session.plist` 加密检测→
manifest/page/asset 解析→`%PDF-` 嗅探→`CREATE_
RECORDING` 同步→副本导入）+ `NotabilitySessionParser`
（`GLKeyedArchiver`/`bplist00`/小端 IEEE-754/`Inked
SpatialHash`）—— iOS `.note` 格式导入保真实现。

## 后果

Harmony `.note` 导入保真原版（含 500MB 上限/magic
嗅探/未映射类型 fail-closed）；`.ntb` 经同步或待办。
