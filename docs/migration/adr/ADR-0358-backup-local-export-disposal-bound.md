# ADR-0358：本地导出销毁绑定

Status: Accepted - Phase 381（2026-08-24）

## Context

`BackupPage.exportAllLocal()` 在取得笔记列表后只做一次生命周期检查。随后逐条等待 `exporter.exportToFile()`，
该调用可打开系统保存器并等待用户操作。若用户在任意一次保存器或导出 await 期间离开页面，循环会继续处理剩余
笔记；迟到成功还会发布旧页 toast。

## Decision

- 每次调用 `exportToFile()` 前先检查捕获的 `lifecycleGeneration`；陈旧态立即静默返回。
- 每次 `exportToFile()` 返回后再次检查同一 generation；陈旧态不递增 `exported`、不继续循环、不发布结果。
- 活动页的导出语义与用户取消语义不变；既有 finally 继续清理 busy/status 并释放备份操作租约。

## Consequences

离开或换代后的旧导出任务不会再打开新的系统保存器，也不会把剩余文件写入用户不再可见的任务流。真实系统选择器
取消行为、多窗口表现与磁盘故障仍需后续设备级验收。本决策不启动模拟器、虚拟机、真机或 Hypium。
