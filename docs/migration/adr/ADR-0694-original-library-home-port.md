# ADR-0694：原版 Library Home 分区移植（ajh/ksh/vdh）

- 状态：Accepted
- 日期：2026-09-25
- 证据：`docs/migration/evidence/original-library-home-port-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-library-home.mjs`
- 关联：ADR-0691（旗标判定更正）、ADR-0655（初登记）、ADR-0652
  （Learn fail-closed 维持）

## 背景

`LIBRARY_HOME`（`ac4.F0`，PRODUCTION 级，打包默认 true）→
1.0.3 原版资料库侧栏首位为 Home 分区：`ksh` 首页组合（头部 +
双 CTA 卡 + Favorite notes/Recent notes 横排卡行 + Learn 区）。
Harmony 此前缺该分区（ADR-0655 误登记为旗标关闭，Phase 743
更正为延迟移植缺口）。本阶段完成移植。

## 决定

1. `LibrarySection.HOME=4`：伪分区挂在既有选中态字段（原版
   Home 是导航项而非 `dk9` Section，`vdh.b` 按选中项分发内容
   宿主 —— 语义同构）。
2. `LibraryViewModel`：HOME 空查询 → `getAllNotes`（主列表
   保持装载以维持既有徽章/提示逻辑）；HOME+查询 → 全库搜索
   （原版 Home 无分区搜索域）；`homeFavorites`/`homeRecents`
   由 `loadNotes` 在 HOME 选中时经既有 repo 投影填充。
3. `LibraryPage`：侧栏/compact drawer 首位 Home 行；
   内容宿主在 `currentSection===HOME && folderId===null &&
   search 空` 时渲染 `HomeContent`；双 CTA 经既有
   `createAndLaunch` 通道（`autoRecord` 即原快捷录音路径）。

## 维持 fail-closed 的子面

- `home_study_up_next` + `learn_card_*`：Learn 后端（ADR-0652）。
- `home_take_notes_starter`/`_subtitle` 配额变体：订阅配额
  （`ab7.k` 订阅态门控），Harmony 无订阅体系（ADR-0662）。

## 记录在案的偏差

- CTA 卡固定等宽横排（原版按标题折行测量自适应整宽堆叠）。
- Home 卡副标取 updatedAt；原版 Home 行日期字段未逐字段证实。
- Home 卡沿用 NoteCard 长按多选；原版 Home 卡交互集未完全解码。
- Home 态保留搜索/排序顶栏；`home_options` 菜单未解码。

## 影响

- 变更：`RepositoryInterfaces.ets`（+枚举值）、
  `LibraryViewModel.ets`（+2 字段 + 装载 + 查询映射）、
  `LibraryPage.ets`（+2 导航行 + 内容分发 + 3 builder）、
  `string.json` base+zh_CN（+9 键）。
- 行为：默认含 Home 分区入口与首页内容；双 CTA 可建普通/
  录音笔记；收藏/最近非空出横排卡行。
