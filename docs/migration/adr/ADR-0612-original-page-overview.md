# ADR-0612 原版页面管理面板（content manager 页总览）

- 状态：Accepted
- 日期：2026-09-23
- 关联 Phase：645
- 证据：`docs/migration/evidence/original-page-overview-jadx-2026-09-23.md`
- 接续：ADR-0608（编辑器 Share 入口）、多选分歧见 Phase 550/635/638 登记

## 背景

原版编辑器顶栏第一项（`x90.g` → `fh2` → `gs8` case 2，
`content_manager_toggle`）打开页面管理面板：VM 为 `qd2`（当前页 /
页列表 / 缩略图 / 过滤器 / 多选态 / 页内搜索态），过滤枚举 `nd2` =
ALL(0)/BOOKMARKS(1)/NOTES(2)，标题 `content_manager_title` = "Pages"。
Harmony 编辑器此前没有任何页缩略图栅格表面——`PageManagerBar`
只是底部动作条。

## 决定

1. `EditorToolbar` 顶栏**首项**新增页面面板开关（▦，a11y
   `cd_pages_panel_toggle`），位于工具与 undo/redo 之前，与原版
   `fh2`/`gs8(z,2)` 的位置一致；门禁与兄弟入口一致
   （photoImportLease/pageOperationBusy/historyPending）。
2. 新增 `PageOverviewPanel`，以 `bindSheet`（LARGE，禁默认关闭叉，
   面板内自绘 ✕ 配 `cd_pages_panel_close`）承载：
   - 标题 `pages_panel_title`（对齐 "Pages"）；
   - 三枚过滤 chip，常数序镜像 `nd2`（ALL=0/BOOKMARKS=1/NOTES=2）；
   - `Grid` 4 列缩略图（`ThumbnailRenderer`，串行 Promise 链逐张
     渲染，避免并发栅格化风暴）；
   - 当前页 accent 描边、书签角标（`bookmark_tall_fill` 语义）、
     页号；点击 cell → `onJumpToPage`（复用页跳门禁）；
   - 过滤为空渲染 `pages_panel_empty`（对齐
     `ui_pageselection__no_pages`）。
3. NOTES 过滤语义 = 「页面有内容」：新增
   `StrokePersistence.getPageElementCounts`（`page_element_snapshot`
   按 `page_id` 分组计数），行数 > 0 的页才在 NOTES chip 下显示。
4. 缩略图失效：宿主在 `onUndoRedoChanged` 递增 `pageContentVersion`，
   作为 `thumbRevision` 注入；cell key 携带页身份 + 几何/模板字段 +
   修订种子 + 主题，`@Watch(cellKey)` 触发重渲染；元素计数随修订
   种子一并刷新（`@Watch(thumbRevision)`）。
5. 生命周期：面板/每个 cell 自持 `PixelMap`，消失时 `release()`；
   面板消失时 `renderer.dispose()`；异步结果按 generation/disposed
   丢弃并释放迟到的 PixelMap。

## 与原版差异（fail-closed / 登记后续）

| 原版能力 | Harmony 现状 | 处置 |
|---|---|---|
| 多选模式（`isSelecting`/`selectedPageIds`/`tfh` 工具条/select_all） | 未实现 | 登记后续 Phase（沿用 Phase 550/635/638 分歧登记） |
| 页内搜索（`isSearchActive`/`searchMatchingPageKeys`） | 未实现 | 登记后续 Phase |
| 缩略图页上下文菜单（`vc2`） | PageManagerBar 覆盖主要页操作 | 已覆盖，菜单入口差异已登记 |
| 面板形态（侧栏 vs 半屏 Sheet） | `bindSheet` LARGE | ArkUI 形态差异，行为等价 |
| NOTES 过滤「内容」判定 | `page_element_snapshot` 行数 | 原版判定字段未反编译完全，按快照行数近似并在此登记 |

## 验证

- `d05-original-page-overview.mjs`：47 断言全绿（原版字符串/`qd2`/
  `nd2`/`n9j`/`gs8`/`x90` 顺序证据 + Harmony 面板/工具栏/持久层/
  双语资源）。
- 全量 Desktop Replay：530/530。
- `note@ohosTest` / `note@default` clean 构建成功（无新增 ArkTS
  错误；`@Watch` 仅能装饰属性，编译期已验证修正）。
- 未运行模拟器/真机/Hypium。
