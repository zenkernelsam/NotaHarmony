# Phase 150 修复总结：系统 Backup Ability 快照闭环

## 基线

审计总纲 2 的 M2-B-04 指出系统 Backup Ability 为空壳且未注册。SDK 证据确认 `@kit.CoreFileKit` 提供 `BackupExtensionAbility`、`BackupExtensionContext.backupDir` 和 `BundleVersion`。

## 已完成

- 新增 `note/src/main/ets/notebackupability/NoteBackupAbility.ets`。
- 只备份 `filesDir`、`databaseDir`，不把 cache/temp 纳入持久快照。
- 使用 staging -> manifest -> 原子发布流程，避免半批次被系统视为成功。
- manifest 约束 schema、相对路径、文件数（10000）和总大小（256 MiB）。
- 恢复逐项校验 manifest 和源文件大小，拒绝绝对路径、盘符、`..` 越界路径。
- 恢复拒绝同一根目录下的重复 manifest 对象，避免重复写入掩盖快照损坏。
- 实现 `onBackup/onRestore`、`onBackupEx/onRestoreEx`、`onProcess/onRelease`。
- 在 `module.json5` 注册 `type: backup` 扩展并加入 `backup_config.json`。

## 重放与构建

静态重放：`node docs/migration/replays/d02-system-backup-ability.mjs`，预期 `TOTAL=7 FAILED=0`。

已完成 `note@default assembleHap` 构建。`note@ohosTest` 和系统服务实际触发仍需本阶段后续验证。

## 未闭环/真机待测

- 系统 Backup 服务实际调用回调。
- 跨 bundle 版本恢复和真实配额/中断场景。
- 恢复后 UI 状态刷新与全量数据回归。
