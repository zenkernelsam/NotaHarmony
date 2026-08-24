# ADR-0331：资料库文件夹选择生命周期绑定

Status: Accepted - Phase 354（2026-08-24）

## Context

selectFolder 会等待 ViewModel 的文件夹查询，再发布 notes、刷新缩略图、关闭抽屉；失败时可能恢复 folder 并弹
toast。此前续体只检查 request generation/ViewModel/query/folder，未捕获 lifecycle generation。页面销毁或重建后，
旧请求仍可修改旧实例状态并显示错误。

## Decision

- selectFolder 进入时捕获 lifecycleGeneration。
- 查询成功后的初次 guard、缩略图刷新后的抽屉关闭 guard，以及 catch 中的失败提示 guard 都传入该生命周期身份。
- isCurrentNotesRequest 继续统一校验 pageActive、lifecycle、request generation、ViewModel、query、folder。
- finally 保持 folderBusy 复位；durable 文件夹与笔记数据权威不变。

## Consequences

旧页面实例不能被过期文件夹选择结果打扰。真实设备快速返回、连续切换和失败注入矩阵继续独立开放。
