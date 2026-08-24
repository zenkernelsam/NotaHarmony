# ADR-0362：录音待删除发布销毁绑定

Status: Accepted - Phase 385（2026-08-24）

## Context

`OriginalRecordingDeleteController.startCommit()` 的 `.finally()` 必须清理 pending、注销 commit 并调用
`publish()`，否则后续 flush 或重试会看到脏状态。该 publish 可在 `NotePage.aboutToDisappear()` 触发 flush 后
到达。页面常规待删除监听此前无条件写入 `pendingRecordingDeleteIds` 并重建时间轴；失败监听已有销毁门禁。

## Decision

- 控制器 `.finally()` 的 durable 清理和发布顺序保持不变。
- `NotePage` 常规待删除监听先检查 `editorDisposed`；陈旧发布不修改状态、不重建时间轴、不触达旧 UI。
- 活动页的待删除撤销窗口、时间轴过滤、提交后刷新和失败 toast 语义不变。

## Consequences

销毁后的旧编辑页不再接收迟到 pending 发布。真实路由返回、后台提交失败和快速删除矩阵仍需后续设备级验收；
本决策不启动模拟器、虚拟机、真机或 Hypium。