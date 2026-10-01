# Phase 1409 — 库视图切换图标 + 笔记卡带标题可访问性

> 证据基线：`decompiled_1.4.2`（sof.java / l9b.java / mo2.java /
> wbn.java / strings.xml / drawable xml）。

## 1. 原版证据

### 1.1 视图切换钮（sof）

```java
if (l69Var == l69.F) {                       // 当前 = 列表模式
  hdcVarH = yb0.A(R.drawable.feature_library__grid_view, …);
} else {
  hdcVarH = a75.h(R.drawable.ui_designsystem__list_bullet, …);
}
strW0 = w0(l69 == F ? cd_switch_to_grid_view : cd_switch_to_list_view);
i87.b(hdcVar, strW0, …);                     // 图标钮(icon, cd)
```

- 图标描绘**目标模式**：list 态显示 `grid_view`，grid 态显示
  `list_bullet`。
- cd 为「Switch to grid/list view」动作句，而非静态模式名。
- `feature_library__grid_view.xml`：24×24，四枚 9×9 描边圆角方块
  （stroke #000, sw=1.25, rx=2）。
- `ui_designsystem__list_bullet.xml`：24×24 fill 矢量，三横线 + 三圆点
  子弹列表。

### 1.2 笔记卡多选勾选圈 a11y（l9b，grid 卡 + list 行同构）

```java
// case0(grid) 与 default(list) 两分支同构：
str = card.title（物化标题）
z   = q0bVar.j（选中态）
strV0 = z ? v0(cd_deselect_note_titled, str)   // "Deselect note %1$s"
          : v0(cd_select_note_titled, str)     // "Select note %1$s"
f9n.b(w8aVarK, z, strV0, …)                    // checkbox(选中态, cd)
```

- 原版 strings.xml 只有带标题变体（无无标题 fallback）——`str` 上游已
  物化为卡片显示标题。
- `mo2`（设置侧笔记选择面）复用同一措辞 `feature_settings__cd_*_
  note_titled`——同一措辞簇，跨模块一致。

### 1.3 顺带核实的相邻行为（本阶段不实现，登记）

- `wbn` ~L1840-1915：笔记卡滑动动作行 `cc3.l`×2——favorite/unfavorite
  swipe（star 图标 + "Favorite note \"%s\""）与 delete swipe（trash +
  "Delete note \"%s\""），`z3` 门控（非多选态）。ArkUI
  `ListItem.swipeAction` 可实现，但属交互面新特性，留给后续 Phase。
- `ui_templates__repeat_template`：strings.xml 中声明但 1.4.2 全源码
  零引用（死串），无可移植语义。
- `t7f`/`n2b`/`b8f`/`wgm`/`olm`/`h07`：save-as-template 创作面 + 页范围
  选择器（"All pages"/"Select pages"），写路径为远端 `wa3`/`ta3` 后端
  → 随 My Templates 保持 fail-closed。
- `xcm`/`ia6`：Gallery 搜索为远端分页（page-size 30，`i36` 仓）→
  fail-closed。
- `feature_library__flashcard_import_*`：`hh5` 计数上传（分块写后端）
  → fail-closed。
- `feature_library__home_coming_up_*`/`feature_settings__calendars*`：
  系统日历服务依赖 → fail-closed。

## 2. Harmony 落点（本次变更）

| 原版 | Harmony |
|------|---------|
| `grid_view`/`list_bullet` 矢量图标 | `TOOL_GLYPHS` 新增 `grid_view`（o 层 4 方块描边，sw=1.25）+ `list_bullet`（f 层 fill，pathData 与原版逐字节一致） |
| sof 目标态图标 | 工具条 `Button` 内 `ToolGlyph{ glyph: listView?'grid_view':'list_bullet' }`（替换 ⊞/☰ 文本符号） |
| cd_switch_to_grid/list_view | 切换钮 `accessibilityText(listView ? cd_switch_to_grid_view : cd_switch_to_list_view)` |
| l9b 带标题勾选圈 cd | `SelectCircle` → `cd_(de)select_note_titled`，参数 `noteDisplayTitle(note)`（空标题回落 `untitled_note`，与卡片 Text 显示一致；对应原版 str 上游物化） |
| l9b grid/list 双分支 | `SelectCircle` 为 grid 卡与 list 行共用 builder，单点修改覆盖两分支 |

新增字符串（en/zh）：

- `cd_select_note_titled` = "Select note %1$s" / "选择笔记 %1$s"
- `cd_deselect_note_titled` = "Deselect note %1$s" / "取消选择笔记 %1$s"
- `cd_switch_to_grid_view` = "Switch to grid view" / "切换到网格视图"
- `cd_switch_to_list_view` = "Switch to list view" / "切换到列表视图"

## 3. fail-closed / 差异记录

- 滑动动作（favorite/delete swipe）在本阶段仅登记证据：Harmony 侧
  `ListItem.swipeAction` 可实现，但删除为破坏操作、原版 `function1`
  语义（直删 vs 进 Recently Deleted）需先核实 `wbn` 调用方——留给
  后续 Phase，当前不引入半证实交互。
- `feature_settings__cd_(de)select_note_titled`（`mo2` 设置侧选择面）：
  Harmony 尚无该设置面（账户/备份相关），不引入。
- 主题按钮（Button($r(theme)) 文本形态）维持现状——原版对应面
  呈现层差异，非本阶段范围。

## 4. 验证

- `node docs/migration/replays/d02-original-library-view-a11y.mjs` → 29 checks OK
- 全量 Replay 基线：PASS=1261 FAIL=0
- `hvigorw assembleHap -p product=default -p module=note@default` → BUILD SUCCESSFUL
- `hvigorw clean && assembleHap -p module=note@ohosTest` → BUILD SUCCESSFUL
