# Phase 151 修复总结：Backup manifest 重复对象拒绝

## 修复

`NoteBackupAbility.validateManifest()` 新增对象身份集合，以 `root:relativePath` 去重；重复对象在任何恢复写入前失败。这样不会重复覆盖应用数据，也不会把重复 manifest 条目误当作成功集合。

## 验证

`d02-system-backup-ability.mjs`：`TOTAL=8 FAILED=0`。

本阶段未启动设备、模拟器、虚拟机或 Hypium；系统 Backup 服务实际触发仍待 M2-RELEASE。
