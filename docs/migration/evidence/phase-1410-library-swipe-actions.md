# Phase 1410 — 库 list 行 + 侧栏文件夹滑动操作

> 证据基线：`decompiled_1.4.2`（wbn.java / qbn.java / d2n.java /
> ucb.java / wpa.java / cc3.java / strings.xml / drawable xml）。

## 1. 原版证据

### 1.1 笔记 list 行滑动操作条（wbn.c + qbn.g）

`wbn.b`（`m5j.b` list 行渲染宿主，`qbn.g` 卡片修饰符内嵌拖动手势
`cgh`/`jbb` 状态）在行尾缘挂一条随滑动揭示的操作条：

```java
// wbn.c 内部：
float fR = o6k.r((-f) - fM0, 0.0f, f3);      // 尾缘揭示宽度（负向拖距）
boolean z3 = fR >= f3 * 0.6f;                // ≥60% 揭示才渲染按钮
Row(宽度 = fR) {
  if (z3) cc3.l(                             // 左位：favorite 钮
    z ? unfavorite_outline : favorite_outline,
    v0(z ? unfavorite_note_swipe_action      // "Unfavorite note \"%s\""
         : favorite_note_swipe_action, str), // "Favorite note \"%s\""
    function0, …);
  Spacer(weight=1);
  if (z3) cc3.l(                             // 右位（贴屏幕边缘）：delete 钮
    trash, v0(delete_note_swipe_action, str),// "Delete note \"%s\""
    function1, …);
}
```

回调链（`wbn.b` L474-489）：

- `function15 = ucb(function1, cghVarH)`（F=1 分支）：
  `!cgh.b() → invoke()`（未完全揭示/落定→执行动作），否则
  `cgh.a()`（已落定→收起归位）。
- `function16 = wpa(rgaVar, 18)`：`rgaVar.setValue(…)` 置布尔态——
  由外层消费为**删除确认框显示态**（非直删）。

`qbn.g`：`p0n.i(mod, cgh, (z2||z5) ? false : true, …)`——选择/编辑
态下禁用滑动手势。

### 1.2 侧栏文件夹行（d2n.c）

同构揭示条，仅 delete：`cc3.l(trash, v0(sidebar_delete_folder_
swipe_action, title), function4)`，`fR ≥ fM0*0.6` 门控，回调起
`kcj` 文件夹删除确认框。

### 1.3 矢量资源（逐字节提取，脚本比对一致）

| drawable | 层 | 结构 |
|----------|-----|------|
| `favorite_outline` | stroke sw=1.25 | 完整星形描边 |
| `unfavorite_outline` | stroke sw=1.25 | 星形残段 ×2 + 对角斜杠 |
| `trash` | stroke sw=1.25 | 桶身+盖+柄+三条内线 |

## 2. Harmony 落点（本次变更）

| 原版 | Harmony |
|------|---------|
| `wbn.c` 尾缘揭示条 [favorite][spacer][delete] | `ListItem.swipeAction({end})` —— `NoteSwipeActions` = Row{56vp accent 底 favorite 钮, 56vp danger 底 delete 钮}（end 揭出方向 = 原版尾缘） |
| `(un)favorite_outline` + 带标题 cd | `ToolGlyph` glyph 按 `note.favorite` 双态切；`accessibilityText($r(…swipe_action, noteDisplayTitle(note)))` |
| `ucb` invoke / `wpa` 置态 | favorite 钮 → `toggleNoteFavorite`（VM 写路径复用）；delete 钮 → `confirmDelete`（原版确认框语义等价） |
| `qbn.g` 选择态禁滑 | `swipeAction(isMultiSelecting ? {} : {end})` |
| `d2n.c` 文件夹 delete | `FolderNavigationList` ListItem `swipeAction({end})` → `FolderSwipeAction` = 48vp danger 底 trash 钮 → `confirmDeleteFolder`（kcj 确认框既有实现） |
| `edgeEffect` | `SwipeEdgeEffect.Spring`（原版回弹语义） |

新增字符串（en/zh）：

- `favorite_note_swipe_action` = `Favorite note "%1$s"` / 收藏笔记“%1$s”
- `unfavorite_note_swipe_action` = `Unfavorite note "%1$s"` / 取消收藏笔记“%1$s”
- `delete_note_swipe_action` = `Delete note "%1$s"` / 删除笔记“%1$s”
- `delete_folder_swipe_action` = `Delete folder "%1$s"` / 删除文件夹“%1$s”
  （对应原版 `sidebar_delete_folder_swipe_action`，Harmony 键名去掉
  sidebar 前缀——语义即侧栏行）

## 3. fail-closed / 差异记录

- 原版的 ≥60% 揭示才渲染按钮（`z3` 门）是呈现进度细节：ArkUI
  `swipeAction` 的 end builder 随揭示即显（框架自带滑入渐显），
  不复制 60% 阈值——行为差异仅限揭示过程中的图标淡入时机。
- 原版 `ucb` 的「已落定→点击归位」语义在 ArkUI 无对应（框架管理
  揭示态，点击动作即触发）；Harmony 钮点击始终执行动作。
- 滑动揭示条的两区间底色（原版 `a.f.a`/`a.g.a` token 不可静态判
  名）以 accent/danger 近似——语义色对齐，非逐色值。
- 文件夹行滑动无多选禁用门（Harmony 文件夹无多选模式；原版
  `z2/z5` 门对应文件夹编辑/拖拽态，Harmony 侧长拖为竖向手势，
  与横向滑动无手势冲突）。
- grid 卡不挂滑动（原版同——GridItem 无滑动语义，滑动操作条仅
  存在于 list 行）。

## 4. 验证

- `node docs/migration/replays/d02-original-library-swipe-actions.mjs`
  → 31 checks OK
- `d02-original-library-home-delta.mjs` 的 Phase-787「无
  swipeAction」delta 钉已反转为实现断言（7/7）。
- 全量 Replay 基线：PASS=1262 FAIL=0
- `note@default` / clean `note@ohosTest` → BUILD SUCCESSFUL
