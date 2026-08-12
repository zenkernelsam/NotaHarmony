# ADR-0156: 系统 Backup 恢复全量预检

## 决策

`NoteBackupAbility.restoreSnapshot()` 在复制任何目标文件前，先遍历 manifest 的全部条目，确认每个源文件存在且实际大小匹配。所有预检通过后才进入 `restoring` 阶段执行复制。

## 原因

原实现边校验边复制。批次中后面的文件损坏时，前面的文件已经写回，恢复失败却留下部分新状态。系统备份与 WebDAV 恢复应共享“完整批次先验证，再开始本地写入”的安全边界。

## 验收

静态 replay 检查恢复方法包含独立的预检循环、预检后才出现 `copyFileSync`，并更新 `restoring` 阶段状态。
