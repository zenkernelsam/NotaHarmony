# Phase 1411 — Document Defaults 自动笔记标题（1.4.2 证据）

> 目标：把原版「文稿默认值 → 默认笔记标题」链路完整移植——偏好持久化 +
> `mcn.g` 自动标题格式化 + 建笔记时生成 + 设置页三态 UI + Example 预览。

## 原版证据（decompiled_1.4.2）

| 类 | 行为 |
|----|------|
| `o8b.java` | DataStore 名 `noteEditorSettings`；键 `defaultNoteTitle` / `includeDatePosition` / `includeTimePosition` / `undoRedoTapsEnabled`。解码：title 键缺失→`null`（`j8b.z`）；date 缺省 `hmi.SUFFIX`；time 缺省 `hmi.NONE`；非法名→解码失败回落缺省。 |
| `o8b.f(l, j, fallback)` | 读 `j8b`：`str2=z；if (str2 != null) str = str2`（**空串也覆盖 fallback**）→ `mcn.g(str, A, B, j)`。 |
| `hmi.java` | 枚举 `NONE("None")`/`PREFIX("Prefix")`/`SUFFIX("Suffix")`，按 name 序列化。 |
| `mcn.g(base,datePos,timePos,j)` | `zq.M(j)`=ofLocalizedDate(**MEDIUM**)（`tgh(10)`）；`zq.e`=ofLocalizedTime(**SHORT**)（`tgh(11)`）。组装：`[date若PREFIX, time若PREFIX] + base若非blank + [date若SUFFIX, time若SUFFIX]`，`r0h.T0`(isNullOrBlank) 丢弃空基题，单空格 join。 |
| `k59.l(j)` | `h45.b(h35.R0)` 旗标关 → `k()` = `data_library_state__default_note_title`（"New Note"）；开 → `o8b.f(...,ui_notedefaults__default_note_title_fallback="Note")`，结果 blank → `"..."`。 |
| `h35.java` | `R0 = DOCUMENT_DEFAULT_SETTINGS`，`qd5` 调试旗标（PRODUCTION ≤ DEBUG 不满足 → 出货版关闭）。 |
| `je.java` case11 | 草稿字段 ≤200 UTF-16 码元才入 state。 |
| `yob.java` | note_title 子屏：case0=字段（非空时尾部 `xmark_circle_fill` 清除钮）/ case1=include_date / default=include_time。 |
| `ibb.java` | 三态位置选择器（None/Prefix/Suffix 下拉），行尾显示当前标签。 |
| `a96.java` | `Example:` + `mcn.g(草稿,位置,remember{now})`——预览**不**套 title fallback。 |
| `j8b/zf3/e8b/yf2` | 设置目录 `document_defaults`→`note_title` 入口（c1 case2）。 |

## Harmony 落地

- `EditorSettingsStore.ets`：`defaultNoteTitle`/`includeDatePosition`/
  `includeTimePosition` 同键持久化（preferences `noteEditorSettings` 同名）；
  `getDefaultNoteTitle` 缺键→`null`、存空串→`''`；`sanitizeTitlePosition`
  非法值回落缺省（date=`Suffix`、time=`None`）。
- `OriginalNoteTitlePolicy.ets`：`NOTE_TITLE_POSITION_*`（存英文名）+
  `formatOriginalAutoNoteTitle`（`Intl.DateTimeFormat` `dateStyle:'medium'`/
  `timeStyle:'short'`；前缀→基题(/\S/ 非 blank)→后缀，`join(' ')`）+
  `ORIGINAL_AUTO_TITLE_EMPTY_FALLBACK='...'`。
- `LibraryViewModel.createNote`：`noteTitleFactory(Date.now())` 异步生成，
  工厂缺失/异常 fail-closed → `ORIGINAL_NOTE_DEFAULT_TITLE`（= "New Note"，
  即 flag-off 分支等价）。
- `LibraryPage`：注入工厂（读三偏好 + 本地化 "Note" fallback → formatter →
  blank→`"..."`）。
- `SettingsPage`：Document Defaults 区——200 上限字段 + `close_med_regular`
  清除钮 + include_date/time 行（尾部当前标签）+ `TitlePositionDialog`
  三态勾选 + Example 实时预览（`noteTitleExampleTs` 记住进屏时刻）。

## 已知迁移差异（见 ADR-1347）

- 原版 `DOCUMENT_DEFAULT_SETTINGS` 是 `qd5` 调试旗标，出货版整个特性隐藏、
  `k59.l` 恒返回 "New Note"；Harmony 无条件开放（无 flag 基建，隐藏可用
  功能反而不还原）。**默认状态下行为等价**：defaultNoteTitle 缺省 →
  "Note" + date Suffix → 新笔记标题形如 "Note 2026/8/9"。

## 验证

- `d02-original-auto-note-title.mjs`：112 checks（双端锚定——decompiled
  键/格式化/旗标语义 + Harmony 键/缺省/组装/UI 锚点）。
- 更新 `d02-local-set-metadata-title-outbound.mjs`（factory 化 createNote
  重锚定 + `/\S/` 替 `.trim(` 守住既有「标题字段禁 trim」pin）。
- 更新 `d02-original-create-from-template.mjs`（repo.createNote(title,...) 锚）。
