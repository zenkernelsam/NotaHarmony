# Phase 168 修复总结：备份 Manifest 批次身份绑定

## 发现

恢复页按 WebDAV 文件名发现 manifest，却只信任 JSON 内部 `batchId`。文件被重命名或放错目录时，会从不同批次目录下载对象，破坏批次原子身份。

## 修改

- `note/src/main/ets/ui/settings/BackupPage.ets`
- 新增 `ADR-0145-backup-manifest-batch-identity.md`
- 新增 `d02-backup-manifest-batch-identity.mjs`

候选文件名现在必须严格等于内部 batch ID 推导出的规范 manifest 文件名，错配候选不会进入最新批次选择。

## 验证

- Replay：`TOTAL=3 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

真实 WebDAV 重命名、错目录和并发发布场景仍需服务端运行态验收。
