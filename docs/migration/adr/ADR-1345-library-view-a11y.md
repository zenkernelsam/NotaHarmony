# ADR-1345：库视图切换图标 + 笔记卡带标题可访问性移植

- 日期：2026-10-01
- 状态：Accepted
- 关联：Phase 1409；库多选 ADR-0640、库多选分享 ADR-0641、页 cell
  a11y ADR-1344

## 背景

原版 1.4.2 库页携带两处未移植的视图/可访问性语义：

1. **视图切换钮**（`sof`）：list 态显示 `feature_library__grid_view`
   矢量（四枚描边圆角方块）+ cd "Switch to grid view"；grid 态显示
   `ui_designsystem__list_bullet`（三横线+三圆点 fill）+ cd
   "Switch to list view"——图标描绘目标模式，a11y 为动作句。
   Harmony 此前用文本符号 `⊞`/`☰`，a11y 仅静态模式名
   （grid_view/list_view）。
2. **笔记卡多选勾选圈 a11y**（`l9b`，grid 卡 case0 与 list 行
   default 两分支同构）：`f9n.b` 的 cd 为带标题的
   `cd_select_note_titled`/"Deselect note %1$s"，`str` 为卡片物化
   标题。Harmony 此前挂静态 `select_note`。
3. 同一措辞簇在 `mo2`（设置侧笔记选择面）以
   `feature_settings__cd_*_note_titled` 复用——措辞证据跨模块一致。

## 决策

- **矢量图标入库**：`TOOL_GLYPHS` 新增 `grid_view`（o 层 4 方块
  描边，sw=1.25）与 `list_bullet`（f 层 fill）；两者 pathData 与
  原版 drawable xml 逐字节一致（机械 diff 校验）。
- **切换钮**：工具条 `Button` 由文本符号改为内嵌 `ToolGlyph`
  （`listView ? 'grid_view' : 'list_bullet'`，20vp，textPrimary
  着色），a11y 换 `cd_switch_to_grid/list_view`。
- **勾选圈 a11y**：`SelectCircle` 的静态 `select_note` 改为
  `cd_(de)select_note_titled` + `noteDisplayTitle(note)` 参数——
  空标题回落 `untitled_note` 物化标题，与卡片 `Text` 显示及原版
  上游物化语义一致；`SelectCircle` 为 grid 卡与 list 行共用
  builder，单点修改覆盖原版 l9b 两分支。
- 新增 en/zh 字符串各 4 条（zh 无原版资源，按既有译文风格补写）。

## 后果

- 库页视图切换钮呈现与 a11y 回归原版（矢量图标 + 动作句 cd）。
- 多选勾选圈播报由 "Select Note" 升级为 "Select note <标题>"。
- 登记不实现（证据已归档于 evidence/phase-1409）：
  - `wbn` 笔记卡滑动动作（favorite/delete swipe，`z3` 门控）——
    可实现但属交互面新特性且 delete 为破坏操作，留后续 Phase；
  - `mo2` 设置侧选择面（无对应 Harmony 面）；
  - `ui_templates__repeat_template` 死串（1.4.2 全源码零引用）；
  - save-as-template 页范围选择 / Gallery 搜索 / flashcard 导入 /
    日历 Coming-up——均为后端/系统服务依赖，保持 fail-closed。

## 验证

- `d02-original-library-view-a11y.mjs` → 29 checks OK
- 全量 Replay 基线 1261/1261 PASS
- `note@default` / clean `note@ohosTest` HAP 构建均 BUILD SUCCESSFUL
