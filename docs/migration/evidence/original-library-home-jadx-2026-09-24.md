# 原版 LIBRARY_HOME 首页分区 — JADX 证据（2026-09-24，Phase 706）

## 旗标

- `ac4.java:182`：`new ac4("LIBRARY_HOME", 47, zb4Var, tsb.c, null)`
  → `ac4.F0`（序号 47 远程旗标）。
- `ajh.java:335`：`if (lc4.a(ac4.F0)) { dsi.a(...R.string.feature_
  library__home, tnc.a...) } else { /* 空渲染 */ }`——旗标开才向
  导航插入 Home 条目。
- `va7.java:30`、`wa7.java:118`：`zA = lc4.a(ac4.F0)` 同门控。

## Home 区组成（ksh 族）

| 位置 | 内容 | 字符串 |
|------|------|--------|
| `ksh.d`（aj5:33 调） | Let's get started 双 CTA 卡 | `home_record_lecture_title/subtitle` + `home_take_notes`（starter: `home_take_notes_starter(%1$d)/_subtitle`） |
| `ksh:287` | Favorite notes 区 | `home_favorite_notes_title` |
| `ksh:878` | Study up next（Learn） | `home_study_up_next_title` |
| `ksh:1125` | Recent notes 区 | `home_recent_notes_title` |
| `oi5`/`pi5`/`hs4`/`haj` | 卡片网格行 | `ksh.g/h` 渲染 |
| `ht8.java:9` | 分析枚举 | `RECORD_LECTURE("record_lecture")` |

附加：`home_subtitle`（"Don't just take notes—learn from them."）、
`home_options`、`home_lets_get_started`。

## Harmony 侧核对

- Library 当前为经典分区（Recent/Favorite/Shared/文件夹 +
  FAB 创建菜单），无 Home 条目/卡片 —— grep `record_lecture`
  `study_up_next` 零命中。
- 功能等价：FAB "Record audio"→`createAndRecord`、
  "New note"→`createAndOpen`；Recent/Favorite 已有库节与
  空态（`d02-original-library-empty-states` 覆盖）。
- Study up next 依赖 Learn 面——ADR-0652 已登记。

## 结论

LIBRARY_HOME 为远程灰度面；Harmony 呈现旗标关闭态（经典库），
按 ADR-0655 登记 fail-closed。
