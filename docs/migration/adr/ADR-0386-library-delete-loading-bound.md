# ADR-0386：资料库删除与权威读取生命周期绑定

- 状态：已接受（2026-08-25）
- 场景：`loadNotes()` 在权威仓储读取期间保持 `isLoading=true`。若用户在等待窗口发起删除，共享 mutation chain 会在事务提交后移除可见卡片，但旧读取仍是活动代；其迟到快照会重新发布已删笔记，并把 `isLoading` 复位为 `false`，造成幽灵卡片和错误加载状态。
- 决策：`deleteNote()` 继续在原 mutation chain 内先完成 durable 删除并投影当前列表；若发现 `isLoading=true`，则递增 `loadGeneration` 并在同一 mutation continuation 中用当前 folder 查询替换旧读取。新读取复用 stale/mutation 重试规则，只在仍为最新代且未被更新 mutation 作废时发布；guarded finally 清除 loading。
- 结果：已提交的删除不再被旧读取复活，权威刷新失败不回滚删除，后续 mutation 也能使替换读取失效。创建路径、文件夹操作、页面生命周期门禁和既有最佳努力 reload 不变。
