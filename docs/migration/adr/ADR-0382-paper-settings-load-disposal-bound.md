# ADR-0382：纸张设置加载销毁绑定

- 状态：已接受（2026-08-25）
- 场景：`PageSettingsPanel.reloadSharedPaperSettings()` 在数据库初始化 await 后继续创建仓库并执行两次列表读取。面板销毁或重载换代后，旧续体仍可发布共享纸张数据、收藏列表并把 `paperStore` 指回数据库。
- 决策：数据库初始化返回后立即联合检查 `panelDisposed || generation !== sharedLoadGeneration`；无效续体在创建仓库和任何存储访问前停止。
- 结果：销毁或已被新加载替代的旧任务不再发布 UI、覆盖 store 或触达数据库；既有收藏、间距与失败门禁保持不变。
