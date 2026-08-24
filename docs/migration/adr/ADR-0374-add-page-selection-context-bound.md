# ADR-0374：新增页选择上下文绑定

- 状态：已接受（2026-08-25）
- 场景：`addPage()` 在持久化返回并通过销毁检查后，先追加页并设置 `currentPageIndex = pages.length - 1`，随后才把 assigned page ID 发布给 Canvas；两帧之间可触发页面切换加载，旧续体再把索引拉回新页。
- 决策：销毁检查后先在更新列表中定位 assigned page 并设置当前索引，再修改 action、发布页列表和推入撤销栈；保证 Canvas 看到的选择与新页一致。
- 结果：消除 add-page 续体与用户切页之间的索引回抢；durable 新页、撤销记录和既有销毁门禁保持不变。
