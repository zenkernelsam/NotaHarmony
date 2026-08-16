# 原版资料库查询与移植侧迟到结果门禁证据（2026-08-16）

## 范围

本证据对应 M2-U-04/M2-U-08 的边修边审补丁。原版基准为
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`，移植侧为
`note/src/main/ets/ui/library/LibraryPage.ets` 与 `LibraryViewModel.ets`。

## 原版硬证据

- `e47.java:356-360` 建立独立的 `search_item(id, noteId, type, subId, pageId, foldedText, rects)`，并以
  `(noteId, type, subId)` 唯一；资料库不是只在 UI 内存中按标题过滤。
- `sq1.java:51-68` 以 `INSERT ... ON CONFLICT(noteId, type, subId) DO UPDATE` 维护索引条目，说明查询观察到的
  是可持续更新的索引状态。
- `vf6.java:39-47` 使用 `foldedText LIKE ? ESCAPE '\\'`，查询结果由数据库异步返回；`d6c.java:70-123` 还显示
  FTS/LIKE 查询作为独立 search engine 入口存在。
- 原版资料库状态由 Room 查询流和页面状态组合提供；Harmony 没有同构的 Compose/Room Flow，因此必须在页面回调
  发布前显式校验“查询文本 + folderId + 请求代次 + 生命周期”。这属于 API 适配，不是臆造原版常量。

## 发现的移植侧竞态

此前 `LibraryPage` 的搜索、folder 切换和 mutation 后权威 reload 只判断 `pageActive` 与 ViewModel 引用。若旧
查询在新查询之后完成，或 mutation reload 在用户改写搜索后完成，旧回调仍可能把 `vm.getFilteredNotes()` 复制到
当前页面，造成搜索框与列表不一致；页面离开/重进也可能留下旧 callback。

## 修复后的门禁

- `notesRequestGeneration` 统一标识页面当前列表请求，页面离开立即递增使迟到回调失效。
- 搜索输入在启动 debounce 时就递增代次；timer 和完成/失败回调同时检查代次与当前文本。
- folder 选择捕获 query/folder/request tuple；只有列表和缩略图成功且 tuple 仍当前时才收起 compact drawer，失败或被
  新请求取代时保留上下文。
- mutation 后 reload 捕获 query/folder/request tuple，并在入口先确认仍属于当前页面 ViewModel；迟到权威结果不再发布。
- init、onPageShow、search-index backfill 也使用同一门禁，避免初始化结果覆盖用户已经发起的查询。

## 回放

`node docs/migration/replays/d02-library-query-generation.mjs` 输出：

```text
D02_LIBRARY_QUERY_GENERATION_REPLAY_OK latest-query=1|folder-query-tuple=1|mutation-reload-guard=1|drawer-close-guard=1|lifecycle-invalidation=1
```

该回放包含旧查询/新查询、folder 切换、页面离开后的请求模型；它是桌面静态/Node 验证，不替代设备输入法、快速
点击和真实网络/数据库延迟验收。
