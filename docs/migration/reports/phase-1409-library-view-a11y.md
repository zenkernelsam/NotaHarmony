# Phase 1409 修复报告：库视图切换图标 + 笔记卡带标题可访问性

## 范围

本阶段接续 Phase 1408 的可访问性对齐主线，处理库页两个此前以
「可用但不对版」状态存在的面：视图切换钮（文本符号 ⊞/☰ + 静态
模式名 a11y）与多选勾选圈（静态 "Select Note" a11y）。同期对
模板/Gallery/导入/日历等字符串簇做了归属审计并登记 fail-closed
结论。

## 原版证据（decompiled_1.4.2）

- `sof`：视图切换钮——list 态显示 `feature_library__grid_view`
  矢量图标 + cd `cd_switch_to_grid_view`；grid 态显示
  `ui_designsystem__list_bullet` + cd `cd_switch_to_list_view`。
  图标描绘目标模式，a11y 为动作句而非模式名。
- `l9b`（grid 卡 case0 / list 行 default 同构）：多选勾选圈
  `f9n.b` 的 cd = `cd_select_note_titled`/`cd_deselect_note_titled`
  （"Select note %1$s"/"Deselect note %1$s"），参数为卡片物化标题。
- `mo2`：设置侧笔记选择面复用同措辞（`feature_settings__cd_*`
  变体）。
- drawable 原文：`grid_view.xml`（24×24，四枚 9×9 圆角方块
  stroke=1.25）、`list_bullet.xml`（24×24 fill，三横线+三圆点）。

## Harmony 实现

- `ToolGlyphs.ets`：新增 `grid_view`（o 层，四方块描边，sw=1.25）
  与 `list_bullet`（f 层 fill）——pathData 经脚本与原版 xml
  逐字节比对一致。
- `LibraryPage` 工具条：`Button('⊞'/'☰')` 文本符号 → 内嵌
  `ToolGlyph`（`listView ? 'grid_view' : 'list_bullet'`，20vp
  textPrimary）；a11y 换 `cd_switch_to_grid/list_view`。
- `SelectCircle`：静态 `select_note` →
  `cd_(de)select_note_titled` + 新增 `noteDisplayTitle()` 物化
  标题参数（空标题回落 `untitled_note`，与卡片显示一致）；
  grid 卡与 list 行共用该 builder，单点覆盖原版双分支。
- 字符串：`cd_select_note_titled`/`cd_deselect_note_titled`/
  `cd_switch_to_grid_view`/`cd_switch_to_list_view` × en/zh。

## Fail-closed / 审计登记

- `wbn` 笔记卡滑动动作（"Favorite/Delete note \"%s\"" swipe
  actions，非多选态门控）：证据已登记；删除为破坏操作且
  `function1` 直删/回收语义待核实，留后续 Phase，本阶段不引入
  半证实交互。
- `ui_templates__repeat_template`：strings.xml 声明但 1.4.2 全
  源码零引用——死串，无可移植语义。
- save-as-template 页范围选择（`wgm`/`olm`/`h07`/`t7f`/`b8f`）：
  写路径为远端模板后端 → 随 My Templates 保持 fail-closed。
- Gallery 搜索（`xcm`/`ia6` 远端分页 page-size 30）、flashcard
  导入（`hh5` 分块上传 + 配额）、日历 Coming-up
  （`home_coming_up_*`/`settings__calendars*` 系统日历服务）：
  均属后端/系统服务依赖，fail-closed。
- `feature_settings__cd_*_note_titled`（`mo2` 设置面）：Harmony
  无对应选择面，不引入。

## 验证

- Replay：`d02-original-library-view-a11y.mjs` 29 项断言全绿。
- 构建：`note@default` 与 clean `note@ohosTest` 均通过。
- 全量 Desktop Replay 基线：1261/1261。
