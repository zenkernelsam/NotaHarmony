# 原版 Library Home 分区（ajh/ksh/vdh）移植证据（JADX, decompiled_1.0.3）

日期：2026-09-25。来源：`decompiled_1.0.3` JADX 输出 +
`resources/res/values/strings.xml`。衔接 Phase 743（ADR-0691
判定更正：旗标默认 true → 延迟移植缺口），本阶段完成移植。

## 原版结构

### 导航入口（`ajh.java:335-356`）

`lc4.a(ac4.F0)`（LIBRARY_HOME，打包默认 true）→ `dsi.a` 导航项
插入 `feature_library__home`（"Home"）+ `tnc.a` 图标，位于
Notes/Shared 之前，即侧栏首位。

### 内容分发（`vdh.java:b`）

`ba6.o(yncVar, tnc.a)` —— 选中项为 Home 时渲染 `ksh.a`
Home 内容而非分区网格。`ab7` ViewModel 供数：
`d`=section、`e`=favorites、`f`=recents、`g`=learn 项、
`k`=配额数（订阅门控）。

### Home 布局（`ksh.a`，57KB composable）

1. 头部：`feature_library__notability_icon` 96dp 图标 +
   `home_lets_get_started`（"Let's get started"，are.C 显示样式）+
   `home_subtitle`（"Don't just take notes—learn from them."）。
2. `ksh.d`：双 CTA 卡等宽横排（`(w-24)/2`），任一标题折行
   >2 行则整体换为整宽堆叠（`o()`/`p()` 文本测量自适应）：
   - "Record a lecture" + `home_record_lecture_subtitle`
   - "Take notes" + `home_take_notes_subtitle`；
     配额态（`num != null`）换为 `home_take_notes_starter`
     "Take %1$d notes for free" + starter 副标。
3. `home_favorite_notes_title` + `ksh.f`/`oi5` 横向卡行
   —— `list.isEmpty()` 时空段不渲染。
4. `home_recent_notes_title` + `yi5` 卡行 ——
   `l96.G` AnimatedVisibility 门 `z2 && !isEmpty`。
5. `home_study_up_next`（Learn 面，`z3` 旗标 + 非空门）——
   Learn 后端 fail-closed 维持（ADR-0652）。
6. 底栏 `zvi.a` 行动条 —— 与既有 FAB overlay 等价。

### 卡片（`ksh.e/g`/`cj5`）

`bfd.t(md8, 220vp)` 固定宽横排卡；`ksh.g` 标题为空回落
`default_note_title`（e5j.h 同款）。

## Harmony 落点

- `LibrarySection.HOME=4`（伪分区，原 dk9 四值序号不动）；
  `SectionNavRow` 在侧栏与 compact drawer 均列首位。
- `LibraryViewModel`：`homeFavorites`/`homeRecents` 在 HOME
  选中时经 `getFavoriteNotes`/`getRecentNotes` 填充（loadNotes
  同源，变异后自动刷新）；HOME 空查询映射 `getAllNotes`，
  搜索按全库语义（原版 Home 非 dk9 Section，无分区搜索域）。
- `LibraryPage.HomeContent`：96vp `startIcon` + 28sp 标题 +
  副标；双 CTA 卡等宽横排 → `createAndLaunch(true/false)`
  （autoRecord 通道 = 原版"Record a lecture"=新建笔记+开录）；
  favorites/recents 非空才出横排 220vp 卡行（复用 `NoteCard`）。
- 字符串：新增 `home`/`home_*` 9 键（base+zh_CN），值逐字
  对版 strings.xml；`home_options`/`study_up_next`/starter 键
  属 fail-closed 面不落资源。

## 记录在案的偏差

- CTA 卡自适应：原版按标题测量折行整宽堆叠；Harmony 固定
  等宽横排（原布局语义差异，无交互差异）。
- Home 卡长按可进多选（复用 NoteCard）；原版 Home 卡交互集
  静态不可完全判定。
- Home 态顶部搜索/排序栏保留——原版 Home 顶栏（`home_options`
  cd 菜单）内容未完全解码，搜索在 Home 选中时按全库出结果。
- Home 卡副标沿用 updatedAt（原版 Home 行日期字段选择未逐
  字段证实）。
