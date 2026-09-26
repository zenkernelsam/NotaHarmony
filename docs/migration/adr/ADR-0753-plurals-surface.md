# ADR-0753 — plurals 资源面收敛与 values 裁剪登记

- 状态：Accepted
- 日期：2026-09-21
- 关联：ADR-0749(strings 面)、ADR-0752(arrays/pen_string)、
  Phase 791 厂商裁剪、Phase 765 学期面、Phase 774/789 画廊、
  Phase 779/788 Learn、Phase 783 贴纸

## 背景

`res/values` 各类型资源在 strings/arrays 之外仍有 plurals、bools、
dimens、integers、colors、styles、public、attrs 未逐类登记版本差异。

## 决策

1. **plurals 为唯一含语义的增量**:16→28，零移除，+12 个新 plural
   全部归属已登记集群(Learn 测验、首页考试倒计时、画廊收藏/粉丝计数、
   贴纸批量操作、笔记上限付费墙、闪卡到期、画廊发布限额)。
   仅登记归属，不虚构 Harmony 文案 —— 对应界面均为后端绑定或未实现
   集群,fail-closed。
2. **其余类型登记为厂商/Compose 裁剪**:dimens 245→129、
   styles 242→37、attrs 1589→400、public 5219→4289、
   integers 20→13、colors 90→77、bools 6→6 不变。
   与 Phase 791/793 的厂商剔除、Compose 化结论一致，无语义增量。
3. **Harmony 复数模式确认**:ArkUI 无 plurals 资源类型,Harmony 用
   `_one`/`_other`/`_singular` 成对键等价覆盖英语的 one/other 两档
   (Android `few`/`many`/`zero` 档在英语文案中本就未使用，无损)。

## 新语义补充

- `feature_library__home_exam_days_until`("In N days")是此前未登记
  的首页考试倒计时文案，补充 Phase 765 学期/日历导入面的 UI 证据。
- `ui_share__gallery_{characters,tags}_remaining` 补充 Phase 789
  画廊发布表单的字段限额语义。

## 后果

- `res/values` 资源面全部收敛：strings(ADR-0749)/arrays(ADR-0752)/
  plurals(本 ADR)含语义面完成登记，其余类型为无语义裁剪。
- Replay `d02-plurals-surface.mjs` 11/11 钉住该结论。
