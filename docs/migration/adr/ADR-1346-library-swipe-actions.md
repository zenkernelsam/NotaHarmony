# ADR-1346：库 list 行 + 侧栏文件夹滑动操作移植

- 日期：2026-10-01
- 状态：Accepted（行为等价；揭示进度细节为呈现层差异，见后果）
- 关联：Phase 1410；库多选 ADR-0640、单笔记菜单 ADR-0513、
  文件夹删除确认（kcj）见 Phase 700 系列

## 背景

原版 1.4.2 库页的 list 行（`wbn.b`/`wbn.c`，由 `qbn.g` 挂拖动
手势）左滑在尾缘揭示 `[favorite][delete]` 操作条；侧栏文件夹行
（`d2n.c`）同样左滑揭示 `delete`。Harmony 此前两处皆无（Phase 787
delta 钉 `d02-original-library-home-delta` 记录了该缺口）。

原版语义要点：

- 揭示 ≥60% 才渲染钮（`fR >= f3*0.6`）；favorite 图标按收藏态
  切 `(un)favorite_outline`，a11y 为带标题的 `…_swipe_action`。
- favorite 点击经 `ucb`：未落定→执行动作；已落定→收起。
- delete 点击经 `wpa(rgaVar,18)` 置确认框态——**不直删**；
  文件夹同。
- 选择/编辑态禁用滑动手势（`qbn.g` 的 `(z2||z5)?false:true`）。

## 决策

- **`ListItem.swipeAction({end})`**：Harmony 的尾缘揭示 API 与
  原版 `-f` 负向拖距尾缘揭示方向一致；`edgeEffect=Spring`。
- **笔记行**：`NoteSwipeActions` = Row{56vp accent 底
  (un)favorite_outline 钮, 56vp danger 底 trash 钮}——favorite
  内排、delete 贴边缘，对应原版 [favorite][spacer][delete]。
  favorite → `toggleNoteFavorite`；delete → `confirmDelete`
  （AlertDialog「Move to Recently Deleted」既有实现，与原版置
  确认态等价）。多选态传 `{}` 禁滑。
- **文件夹行**：`FolderSwipeAction` = 48vp danger 底 trash 钮 →
  `confirmDeleteFolder`（kcj 九宫复数确认框既有实现）。
- **图标**：`TOOL_GLYPHS` 新增 `favorite_outline`/
  `unfavorite_outline`/`trash`，pathData 与原版 xml 逐字节一致
  （脚本 diff 校验）。
- **字符串**：4 个 `*_swipe_action` 带标题 cd（en/zh）；
  `sidebar_delete_folder_swipe_action` 键名去掉 sidebar 前缀
  （Harmony 键表无 sidebar 命名习惯，语义即侧栏行）。

## 后果

- list 视图笔记行与侧栏文件夹行获得原版滑动快捷操作；grid 卡
  不变（原版 grid 无滑动）。
- 呈现层差异（已在 evidence 记录）：ArkUI end builder 随揭示即显
  而非原版的 ≥60% 门；`ucb` 的「落定态点击归位」无对应；两区间
  底色以 accent/danger 语义色近似（原版 token 不可静态判名）。
- Phase-787「Harmony 无 swipeAction」delta 钉闭合。

## 验证

- `d02-original-library-swipe-actions.mjs` → 31 checks OK
- 全量 Replay 基线 1262/1262 PASS
- `note@default` / clean `note@ohosTest` 均 BUILD SUCCESSFUL
