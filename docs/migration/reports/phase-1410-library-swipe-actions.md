# Phase 1410 修复报告：库 list 行 + 侧栏文件夹滑动操作

## 范围

原版 1.4.2 在库页 list 行与侧栏文件夹行提供左滑揭示的快捷操作
（笔记：favorite + delete；文件夹：delete）。Harmony 此前无
`swipeAction`——Phase 787 曾以 delta 钉记录该缺口，本阶段按
`wbn`/`qbn`/`d2n`/`ucb`/`wpa` 证据补齐。

## 原版证据（decompiled_1.4.2）

- `wbn.c`：list 行尾缘揭示条，宽度随 `-f` 拖距增长
  （`fR = (-f)-fM0` 夹取），`fR ≥ f3*0.6` 时渲染两枚 `cc3.l`
  图标钮——左位 favorite（`(un)favorite_outline` 按态切换，
  cd = `…note "%1$s"` 带标题），右位 delete（`trash`）。
- 回调：`ucb`（未落定→invoke，已落定→`cgh.a()` 归位）；
  delete 经 `wpa` 置布尔态 → 外层弹删除确认框（**非直删**）。
- `qbn.g`：选择/编辑态 `p0n.i` 禁滑。
- `d2n.c`：侧栏文件夹行同构——仅 trash + `sidebar_delete_folder_
  swipe_action`，回调起 `kcj` 文件夹删除确认框。
- 矢量：`favorite_outline`/`unfavorite_outline`/`trash` 全部
  stroke sw=1.25 描边。

## Harmony 实现

- `ToolGlyphs.ets`：新增 `favorite_outline`/`unfavorite_outline`/
  `trash`（o 层 stroke，pathData 与原版 xml 逐字节一致）。
- `LibraryPage` list 态 `ListItem.swipeAction({end})`：
  `NoteSwipeActions` = Row{accent 底 favorite 钮（56vp）、
  danger 底 delete 钮（56vp）}，点击分别 → `toggleNoteFavorite`
  （复用 VM 写路径）与 `confirmDelete`（复用既有确认框）；
  `isMultiSelecting` 时传 `{}` 禁滑。
- `FolderNavigationList` ListItem `swipeAction({end})`：
  `FolderSwipeAction` = danger 底 trash 钮（48vp）→
  `confirmDeleteFolder`（kcj 确认框既有实现）。
- 4 个 `*_swipe_action` 带标题 a11y 串（en/zh）。

## Fail-closed / 差异记录

- ArkUI end builder 随揭示即显（无原版 ≥60% 渲染门），`ucb` 的
  落定归位语义由框架管理——呈现层差异。
- 两区间底色以 accent/danger 语义色近似（原版 `a.f.a`/`a.g.a`
  token 不可静态判名）。
- grid 卡不挂滑动（原版同）。
- 文件夹滑动无额外禁滑门（Harmony 无文件夹多选/编辑态）。

## 验证

- Replay：`d02-original-library-swipe-actions.mjs` 31 项断言全绿；
  Phase-787 delta 钉 `d02-original-library-home-delta` 已反转。
- 构建：`note@default` 与 clean `note@ohosTest` 均通过。
- 全量 Desktop Replay 基线：1262/1262。
