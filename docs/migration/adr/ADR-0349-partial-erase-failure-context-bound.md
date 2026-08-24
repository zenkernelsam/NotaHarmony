# ADR-0349：局部擦除失败上下文绑定

Status: Accepted - Phase 372（2026-08-24）

## Context

局部擦除持久化提交的成功续体已有历史页上下文门禁，但拒绝续体先弹保存失败提示，再记录错误；迟到事务异常可
触达已销毁或换代 Canvas，本地快照回退也缺少同一门禁。

## Decision

- 拒绝续体先完成预览清理并保留 durable 错误日志，再用 `isHistoryPageContextCurrent` 联合校验活动页、同代、
  页面身份与加载健康。
- 只有当前上下文才显示保存失败并执行本地回退；陈旧/销毁续体不触达 UI。
- 成功发布契约和 finally 清理不变。

## Consequences

旧 NoteCanvasView 不再因迟到局部擦除事务失败而重建墨迹或弹提示。真实设备快速切页矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
