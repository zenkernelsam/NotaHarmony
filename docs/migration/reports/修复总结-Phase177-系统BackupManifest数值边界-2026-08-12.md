# Phase 177 修复总结：系统 Backup Manifest 数值边界

## 发现

系统 `NoteBackupAbility` 的 manifest 校验只要求文件大小和时间戳为 finite，未拒绝小数或超出 JavaScript 安全整数范围的值。WebDAV 批次链已经使用安全整数，两套系统边界不一致。

## 修改

- `note/src/main/ets/notebackupability/NoteBackupAbility.ets`
- 新增 `ADR-0154-system-backup-manifest-numeric-boundaries.md`
- 新增 `d02-system-backup-manifest-numeric-boundaries.mjs`

恢复现在在复制文件前要求 manifest `createdAt` 为正安全整数、entry `size` 为非负安全整数。

## 验证

- Replay：`TOTAL=5 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

系统 Backup Extension 的真实 CoreFileKit 生命周期、升级恢复和 fault injection 仍需设备运行态验收。
