# Phase 746 — 原版 Library Home 分区移植（ADR-0694）

日期：2026-09-25

## 结论

Phase 743 判定更正后的实质移植：`LIBRARY_HOME`（打包默认 true）
对应的资料库 Home 分区上线 —— 侧栏/compact drawer 首位 Home
导航项 + `ksh` 首页内容（头部标题区 + "Record a lecture"/
"Take notes" 双 CTA 卡 + Favorite notes/Recent notes 横排卡行）。
Learn 子区（study_up_next）与配额 CTA 变体维持 fail-closed。

## 原版证据

- `ajh.java:335`：`lc4.a(ac4.F0)` 门控首位导航项（`tnc.a` 图标 +
  `feature_library__home`）。
- `vdh.b`：`ba6.o(ync, tnc.a)` 分发 `ksh.a` Home 宿主。
- `ksh.a`：96dp 图标 + "Let's get started" + 副标 → `ksh.d` 双
  CTA（等宽横排/折行整宽自适应）→ favorites（非空才渲染）→
  recents（旗标+非空 AnimatedVisibility）→ study_up_next（Learn
  旗标）→ `zvi.a` 底栏。
- 数据：`ab7.e`=favorites、`ab7.f`=recents、`ab7.k`=配额数。

## 变更

- `RepositoryInterfaces.ets`：`LibrarySection.HOME=4`（伪分区，
  dk9 原序号不动）。
- `LibraryViewModel.ets`：`homeFavorites`/`homeRecents` 字段 +
  HOME 选中时装载（getFavoriteNotes/getRecentNotes）+ 查询映射
  （HOME 空查询→getAllNotes；HOME 搜索→全库）。
- `LibraryPage.ets`：两处导航列表首位 Home 行；内容分发 HOME
  分支（搜索非空回落结果网格）；`HomeContent`/`HomeCtaCard`/
  `HomeNoteSection` 三 builder；CTA 走既有 `createAndLaunch`
  （autoRecord 通道）。
- `string.json` ×2：`home`/`home_lets_get_started`/`home_subtitle`/
  `home_record_lecture_title`/`home_record_lecture_subtitle`/
  `home_take_notes`/`home_take_notes_subtitle`/
  `home_favorite_notes_title`/`home_recent_notes_title` 9 键。

## 验证

- 专项 Replay `d02-original-library-home.mjs`：37/37 绿。
- 全量 Desktop Replay：630/630 fixture 绿。
- `note@default` 增量构建绿；clean 双 HAP 见提交记录。

## 记录在案的偏差（ADR-0694）

- CTA 卡固定等宽横排（原版按标题折行自适应整宽堆叠）。
- Home 卡副标取 updatedAt；原版 Home 行日期字段未逐字段证实。
- Home 卡沿用 NoteCard 长按多选；原版 Home 卡交互集未完全解码。
- Home 态保留搜索/排序顶栏；`home_options` 菜单未解码。
