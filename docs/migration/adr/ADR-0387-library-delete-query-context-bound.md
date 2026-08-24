# ADR-0387：资料库删除替换读取查询绑定

- 状态：已接受（2026-08-25）
- 场景：ADR-0386 让删除在权威读取进行中接管并重查当前 folder，但旧实现没有保存 `loadNotes(query)` 的查询词。搜索读取等待期间删除后，replacement 会调用全量或 folder 查询，把未过滤列表发布回搜索视图。
- 决策：`LibraryViewModel` 保存最近一次权威读取的 `activeQuery`；删除接管 loading 时用该 query、当前 folder 与共享 stale/mutation 规则构造 replacement read。搜索、folder、后续 mutation 和生命周期语义保持一致。
- 结果：搜索中提交删除后仍只显示匹配结果；已删笔记不会复活，loading 只由最新有效读取清理。创建路径和既有最佳努力 reload 不变。
