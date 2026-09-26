# Phase 787 证据：原版 1.4.2 库主页增量（Coming-Up/考试/滑动操作）

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml `feature_library__*`
差集（+57，扣去 flashcard 族后 33 键）；Harmony `LibraryPage.ets`。
Replay：`docs/migration/replays/d02-original-library-home-delta.mjs`
ADR：`ADR-0731-original-library-home-delta.md`

## 1. Coming-Up 主页区块（日历后端）

`home_coming_up_*` 十键：`title`/`happening_now`/`starting_soon`/
`earlier_days`/`later_days`/`all_day`/`no_events`/`start_now`/
`untitled_event`/`connect_{title,subtitle}`——主页"即将到来"
日历事件区块（Phase 765 日历族 UI 面，日历权限+事件源为
后端/系统边界）。

## 2. 考试复习区块

`home_upcoming_exams_title`/`home_exam_{review,tomorrow,
open_folder}`——"即将到来的考试"区块（syllabus/calendar
族联动；`exam_review` 跳复习集）。

## 3. 滑动操作（本地 UX 差）

`delete_note_swipe_action`/`favorite_note_swipe_action`/
`unfavorite_note_swipe_action`——库列表行**滑动即删/收藏**
手势键。Harmony 库页无 swipeAction——**真·未移植 UX 差**
（ArkUI List 有 swipeAction 能力，本地可移植）。

## 4. 其余配套

- `add_note_cover`（库内封面入口，接 782）。
- `creating_planner_note`/`planner_failed`（计划本创建
  状态，接 782）。
- `cd_switch_to_{grid,list}_view`（视图切换 a11y——Harmony
  已有 `listView` 状态切换，缺 a11y 标签）。
- `cd_{select,deselect}_note_titled`（多选 a11y——
  选择模式已移植，标签增量）。
- `learn_card_{new,start_learning}`、`template_import_failed`、
  `more_actions`、`gallery` 入口名。

## 5. 分类结论

- Coming-Up/考试区块：日历/syllabus 后端边界。
- **滑动操作**：版本差·本地候选（明确未移植）。
- a11y 标签/入口名：版本差小增量。
