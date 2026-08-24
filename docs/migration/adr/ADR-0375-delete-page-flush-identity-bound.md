# ADR-0375：删除页刷新身份绑定

- 状态：已接受（2026-08-25）
- 场景：`deleteCurrentPage()` 在捕获页面快照前等待 `flushCurrentPage()`；该等待可让 Canvas 完成切页加载并改变当前页。旧续体随后仍按原 page ID 快照当前 UI、持久化删除原页，并把删除后的页列表发布到已切换上下文。
- 决策：flush 返回后先确认 `pages[currentPageIndex].pageId === pageId`；身份漂移则静默取消本次删除。成功路径使用 flush 前计算好的 `selectedAfter`，在发布剩余列表后精确选择目标后继页。
- 结果：不会把新当前页内容快照成被删页历史，也不会对已切换 UI 发布陈旧删除结果；durable 删除语义和失败回滚保持不变。
