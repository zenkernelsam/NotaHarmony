# ADR-0339：资料库变更失败提示生命周期绑定

Status: Accepted - Phase 362（2026-08-24）

## Context

资料库文件夹创建/重命名、删除文件夹、移动文件夹和移动笔记的 durable catch 续体会直接弹 toast。此前成功
发布已有 lifecycle/repo guard，但失败提示没有；快速销毁或重建页面后，迟到异常仍可向旧实例弹错误。

## Decision

- 四个异步变更入口在 catch 内先校验 `pageActive` 与触发时 lifecycle generation。
- 过期失败不弹 toast；仍返回原有 false/void 结果并保留 finally busy 清理。
- 同步拖拽解析中的即时异常不涉及 await 后续体，不改变行为。
- 笔记删除/创建既有完整 catch guard 经复核保持不变。

## Consequences

旧 LibraryPage 不能跨销毁边界显示过期操作失败。真实设备快速删除、移动与返回矩阵仍属后续验收；
本决策不启动设备或 Hypium。
