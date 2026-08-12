# ADR-0145: 备份 manifest 批次身份绑定

## 决策

恢复候选 manifest 只有在 WebDAV 文件名严格等于 `backupManifestFileName(parsed.batchId)` 时才参与最新批次选择。

## 原因

manifest 文件名、JSON 内 batch ID 和对象目录必须表示同一原子批次。只信任 JSON 内 ID 会使重命名、错放或损坏的 manifest 从另一个目录下载对象。

## 验收

静态 replay 检查候选文件名与规范化 batch 文件名相等；真实 WebDAV 错配文件仍需服务端验收。
