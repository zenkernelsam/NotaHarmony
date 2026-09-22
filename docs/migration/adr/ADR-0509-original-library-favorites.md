# ADR-0509：原版库收藏与分区——dk9 四分区 + isFavorited 部分更新

- 状态：已接受（2026-09-22，Phase 537）
- 背景：原版库按 `dk9` 枚举分四区：ALL_NOTES / RECENT /
  FAVORITES / UNFILED（`ua5.java:227` 渲染为 chip 行，
  `pk9.java:67` 默认 ALL_NOTES）。`favorite`/`lastOpened` 是
  一等合并元数据（`x17.java:143` 的 COALESCE 投影），
  `modifyNote` 以可选字段写 `isFavorited`/`lastOpened`
  （`yp1.java`），`setFavorite`/`setLastOpened` 为部分 EDIT——
  **不推进 updatedAt**。RECENT 走 `lastOpened` 降序前 10
  （`mk9` 的 `au1.N1(au1.K1(list, fh7(13)), 10)`），不经分区
  排序；RECENT 卡片日期取 `lastOpened`（gb6.b0）。Harmony
  此前只有 All Notes + 文件夹视图：`note_meta.favorite` 与
  `last_opened` 列存在但无查询/写入路径，无分区导航、无
  收藏动作与徽标。

## 决策

1. `LibrarySection` 枚举沿用 `dk9` 序（ALL_NOTES=0 …
   UNFILED=3），挂于 `RepositoryInterfaces` 供仓储与 VM 共用。
2. 仓储新增：`getFavoriteNotes`（favorite=1，updatedAt DESC）、
   `getRecentNotes`（lastOpened DESC，LIMIT 10）、
   `getUnfiledNotes`（folder_id IS NULL）、`setNoteFavorite`
   与 `touchNoteLastOpened`（单列部分更新，不动 updatedAt）、
   `searchNotesInSection`（分区谓词 + search_item EXISTS）——
   全部沿用 `libraryMetadataMutationMutex.runExclusive` 与
   `deleted_at IS NULL` 过滤约定。
3. `LibraryViewModel`：`currentSection` 默认 ALL_NOTES；
   `setSection` 清空文件夹视图、`setFolder` 重置分区——两者
   互斥，与 pk9 默认语义一致；`queryNotes` 统一派发普通查询与
   分区搜索；`toggleFavorite` 走部分更新并在 FAVORITES 分区
   就地剔除取消项；`applySort` 在 RECENT 直接返回（原版
   RECENT 不经 pk9.s）。
4. `LibraryPage`：侧栏与紧凑抽屉各四枚 `SectionNavRow`
   （图标 + 本地化标签 + 选中态）；上下文菜单按原版位序
   Favorite/Unfavorite → Move → … → Delete；卡片 `TopEnd`
   叠加 `♥` 徽标；RECENT 卡片显示 `lastOpened`；FAVORITES
   空态展示原版 empty_favorite_notes 文案。
5. `NotePage` 打开笔记时 `touchNoteLastOpened(noteId,
   Date.now())`——原版 setLastOpened 部分更新落点。
6. **刻意排除**：收藏翻转不推进 `updatedAt`（x17 部分 EDIT
   不带时间戳），亦不进入同步操作日志——Harmony 当前无
   modifyNote 操作管线，favorite 作为本地元数据列直写；
   若未来接入原版笔记级操作管线，需把 favorite/lastOpened
   迁移为 EDIT 行（已登记）。

## 理由

- `x17` 合并查询证明 favorite/lastOpened 是合并元数据而非
  结构字段——部分更新必须保持 updatedAt，否则收藏动作会
  污染 ALL_NOTES 的"最近修改"序。
- RECENT 的"前 10 + 固定排序"由 `au1.N1(...,10)` 与跳过
  `pk9.s` 共同决定；Harmony 用 `LIMIT 10` + `applySort`
  早退镜像，而非把 RECENT 伪装成一种排序模式。
- 分区与文件夹互斥（选分区清文件夹、选文件夹回 ALL_NOTES）
  来自 `pk9` 默认态与 `ua5` 单选行——避免同时命中两套过滤。

## 后果

- 库分区行为对齐原版：Favorites 有专属空态与上下文菜单
  往返，RECENT 反映真实打开顺序。
- 适配差异（已登记于证据文档）：chip 行→纵向导航行；
  `favorite_fill`→`♥` 字形；`lastOpened` 打点目前仅覆盖
  编辑器打开路径。
- 既有 replay 锚点合法更新 3 处（delete-loading 派发、
  drawer all_notes 锚点、soft-delete 查询计数 2→5）。
