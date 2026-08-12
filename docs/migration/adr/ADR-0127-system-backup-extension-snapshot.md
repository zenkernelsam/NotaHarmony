# ADR-0127：系统 Backup Extension 使用受控应用快照

日期：2026-08-12

## 决策

注册 Harmony `BackupExtensionAbility`，由 `NoteBackupAbility` 在系统提供的 `BackupExtensionContext.backupDir` 下生成应用数据快照。快照只包含 `filesDir` 和 `databaseDir`，排除 cache/temp；先写入 staging 目录，manifest 和全部对象成功后再原子发布为正式快照。

manifest 记录 schema、创建时间、bundle 版本、根目录名、相对路径和字节数。恢复前验证 schema、根目录、路径安全、文件数、总大小和源文件大小，拒绝绝对路径、盘符和 `..` 路径。

## 原版/平台依据

平台 SDK 的 `@kit.CoreFileKit` 导出 `BackupExtensionAbility`、`BackupExtensionContext` 和 `BundleVersion`；扩展注册类型为 `backup`，metadata `ohos.extension.backup` 指向 `backup_config`。该能力不能依赖 UIAbility picker，因此没有强转 `UIAbilityContext` 或复用用户导出对话框。

## 未闭环

本阶段已完成静态实现和构建；系统备份服务实际触发、跨版本恢复和设备存储配额仍需用户后续在设备/模拟器执行 M2-RELEASE 验收。
