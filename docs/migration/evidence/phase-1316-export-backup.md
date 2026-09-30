# Phase 1316 证据 — 导出 + WebDAV 备份层

来源：`data/{NoteExporter,WebDAV*,Backup*}.ets` +
`notebackupability/` + `ui/settings/`。

## `NoteExporter` = `.note` 导出（iOS 格式）

```
exportNote(noteId, includeRecordings):
  format=NOTE_FORMAT  (.note ZIP —— iOS 兼容)
  原版 yk9：录音 audio 并入 note.assets
  （缺一音频中止整个导出）
  assertStableBackupSnapshot/BackupSnapshotChangedError
    —— 快照一致性守卫
exportToFile → tempDir/export_*.note → picker 保存
```

## WebDAV 自动备份

```
WebDAVClient              WebDAV HTTP 客户端
WebDAVConfigStore/
WebDAVConfigTransaction   配置存储+事务
BackupBatch{Applier,      备份批次 应用/发布/恢复
  Publisher,Restorer,Spec}
BackupHash                备份哈希（增量/校验）
BackupOperationLease      备份操作租约
BackupSnapshotGuard       快照一致性（导出期间禁止修改）
NoteBackupAbility         备份 Ability
ui/settings/BackupPage +
WebDAVSettingsPage        备份设置 UI
```

## 语义

导出 = `.note` iOS ZIP（录音并入 assets+快照守卫）；
备份 = **WebDAV 自动备份**（批次+哈希+租约+快照
守卫+配置事务）—— 对应原版库 auto-backup（iCloud/
Drive/WebDAV 等 provider，Harmony 实现 WebDAV）。

## Harmony 决策

`.note` 导出保真（iOS 格式+快照一致性）；备份 = WebDAV
客户端（原版多 provider → Harmony WebDAV）—— 导出/
备份语义保真。

## 产出

- fixture `d02-export-backup.mjs`（10 断言）。
- ADR-1260；中文报告。
