# ADR-0520 — 原版文件夹搜索域

状态：Accepted（Phase 548）

## 背景

原版文件夹内搜索默认限定文件夹，搜索激活时渲染 `bk9`
FolderFilter 的 "Show results for all notes" 开关
（`mhh`/`yj9` folder-filter-toggle），开启后范围扩至全部笔记但
不离开文件夹视图；占位符变为 "Search in \"%s\""（`yj9:852`）。
Harmony 搜索已按文件夹限定，但无扩展开关与文件夹占位符。

## 决策

1. VM 新增 `searchAllNotes`（默认 false）；`setFolder`/`setSection`
   重置并纳入失败回滚；`queryNotes` 在该标志且 folderId 非空时
   改用 `searchNotes(query, null)`。
2. 页面：文件夹态占位符 "Search in \"{name}\""；搜索激活且处于
   文件夹时渲染开关行，切换走 `beginNotesRequest` 守卫链。
3. 字符串 `search_in_folder`/`search_show_all_notes` 双语（EN 与
   原版一致）。

## 验证

`d02-original-folder-search-scope.mjs` 14/14（含域模型断言）；
全套 443/443；`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
