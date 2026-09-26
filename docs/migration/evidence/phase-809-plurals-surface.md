# Phase 809 — 复数(plurals)资源面与 values 资源收敛

## 目的

在 Phase 791(res 总览)与 Phase 808(arrays/pen_string)之后，`res/values`
中仍未按资源类型逐一登记的剩面包括 `plurals.xml`、`bools.xml`、
`dimens.xml`、`integers.xml`、`colors.xml`、`styles.xml`、`public.xml`、
`attrs.xml`。本阶段完成该面的版本对比与集群归属登记，重点为用户可见的
plurals(带数量的文案)。

## 取证路径

- `decompiled_1.0.3/resources/res/values/{plurals,bools,dimens,integers,colors,styles,public,attrs}.xml`
- `decompiled_1.4.2/resources/res/values/*.xml`

## 各资源类型的版本计数

| 资源类型 | 1.0.3 | 1.4.2 | 性质 |
|---|---|---|---|
| plurals | 16 | 28 | **+12 用户可见文案** |
| bools | 6 | 6 | 无变化 |
| dimens | 245 | 129 | 裁剪(厂商/Compose) |
| integers | 20 | 13 | 裁剪 |
| colors | 90 | 77 | 裁剪 |
| styles | 242 | 37 | Compose 化裁剪 |
| public | 5219 | 4289 | 资源 ID 裁剪 |
| attrs | 1589 | 400 | 厂商 attr 裁剪 |

裁剪方向与 Phase 791/793 的厂商剔除结论一致：1.4.2 进一步移除
View 体系样式/attr/public ID,Compose 化程度提高。这些裁剪不含
应用语义，登记在此不再单独成阶段。

## plurals 面(唯一含语义的增量)

1.0.3 的 16 个 plurals 全部保留(库删除/空文件夹计数/索引进度/版本历史/
试用脚注/设置删除确认/笔记上限/文件导入计数等),**零移除**。

1.4.2 新增 12 个，全部落入已登记集群：

| plural 键 | 值 | 归属 |
|---|---|---|
| `feature_learn_quiz__caught_up_cards_studied` | "card(s) studied so far" | Phase 788 Learn 测验 |
| `feature_library__home_exam_days_until` | "In %d day(s)" | **首页考试倒计时** — 新发现的首页小组件文案，与 Phase 765 学期/日历面相关 |
| `feature_library_gallery__collection_note_count` | 收藏集笔记计数 | Phase 774/789 画廊 |
| `feature_library_gallery__follower_count` | 粉丝计数 | Phase 774 画廊社交 |
| `feature_note_stickers__delete_title` | 批量删除标题 | Phase 783 贴纸管理器 |
| `feature_note_stickers__selected_count` | 已选计数 | Phase 783 贴纸管理器 |
| `feature_paywall__note_limit_offer_cta_trial` | 试用 CTA | Phase 788 笔记上限付费墙 |
| `feature_paywall__note_limit_offer_title` | 付费墙标题 | Phase 788 |
| `feature_paywall__note_limit_offer_trial_terms` | 试用条款 | Phase 788 |
| `ui_learn__flashcards_due_count` | 到期卡片计数 | Phase 779/788 闪卡 |
| `ui_share__gallery_characters_remaining` | 剩余字符 | Phase 789 发布表单限制 |
| `ui_share__gallery_tags_remaining` | 剩余标签位 | Phase 789 发布表单限制 |

## 新语义

- **首页考试倒计时**:`home_exam_days_until`("In N days")是此前未登记
  的首页文案 —— 学期/考试日期(Phase 765 日历导入面)在库首页以倒计时
  形式展示。
- **发布表单限额**：画廊发布(Phase 789)的标题字符与标签数量带剩余
  计数提示。

## Harmony 侧模式

Harmony/ArkUI 无 plurals 资源类型。Harmony 已建立的等价模式是
`_one`/`_other`/`_singular` 成对键(`note_selected_singular`、
`import_files_count_one/other`、`delete_notes_message_one` 等，见
`note/src/main/resources/base/element/string.json`)。该模式覆盖原版
plurals 的双数量形式;ArkUI 不支持 Android 的 `few`/`many`/`zero`
数量档(英语文案本身只用 one/other),不构成语义损失。

新增 12 个 plurals 均归属后端绑定或未实现集群(画廊、贴纸、付费墙、
闪卡到期、考试倒计时),在 Harmony 无对应界面，登记为 fail-closed/
未实现，不虚构文案。

## 结论

`res/values` 资源面至此收敛：唯一含应用语义的版本增量是 12 个
plurals(全部归已登记集群，其中首页考试倒计时与画廊发布限额为补充
语义);其余类型为厂商裁剪与 Compose 化裁剪，无语义增量。
