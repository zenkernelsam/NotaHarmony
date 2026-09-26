# Phase 809 — 复数资源面与 values 资源收敛(中文报告)

## 本阶段结论

`res/values` 按资源类型的版本对比完成，**plurals 是其中唯一含应用
语义的增量面**:16→28,零移除，+12 个新 plural 键。

## 新增 12 个 plurals 的集群归属

| 集群 | plural 键 | 新语义 |
|---|---|---|
| Phase 788 Learn 测验 | `caught_up_cards_studied` | "已学 N 张卡片" |
| 首页(新发现) | `home_exam_days_until` | **"N 天后考试"倒计时** — 765 学期面的首页 UI 证据 |
| Phase 774/789 画廊 | `collection_note_count`、`follower_count` | 收藏集/粉丝计数 |
| Phase 783 贴纸 | `delete_title`、`selected_count` | 批量删除/已选计数 |
| Phase 788 付费墙 | `note_limit_offer_{cta_trial,title,trial_terms}` | 笔记上限试用报价 |
| Phase 779/788 闪卡 | `ui_learn__flashcards_due_count` | 到期卡片数 |
| Phase 789 发布 | `characters_remaining`、`tags_remaining` | 发布表单限额提示 |

全部归属后端绑定或未实现集群,Harmony 不虚构对应文案，登记为
fail-closed/未实现。

## values 其余类型

dimens 245→129、styles 242→37、attrs 1589→400、public 5219→4289、
integers 20→13、colors 90→77,bools 6→6 不变 —— 全部为厂商剔除与
Compose 化裁剪，与 Phase 791/793 结论一致，无语义增量。

## Harmony 等价模式

ArkUI 无 plurals 类型，Harmony 用 `_one`/`_other`/`_singular` 成对键
覆盖英语 one/other 两档(Android 其余数量档在英语文案中未使用),语义
无损。该模式此前已建立，本阶段仅确认覆盖。

## 验证

- Replay:`d02-plurals-surface.mjs` 11/11;全量 682/682 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-809-plurals-surface.md`
- `docs/migration/replays/d02-plurals-surface.mjs`
- `docs/migration/adr/ADR-0753-plurals-surface.md`
- 本报告
