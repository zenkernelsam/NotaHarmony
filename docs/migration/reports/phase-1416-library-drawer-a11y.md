# Phase 1416：窄屏库 chrome 与文件夹对话框无障碍语义移植报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 16 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1416-library-drawer-a11y.md`
- 决策：`docs/migration/adr/ADR-1352-library-drawer-a11y.md`
- Replay：`docs/migration/replays/d02-original-library-drawer-a11y.mjs`

## 目标

清理 Phase 1415 onboarding 链收尾时暴露的窄屏库 chrome 无障碍差距：
原版 hamburger 钮/抽屉遮罩/文件夹对话框均有专用 cd，Harmony 挂的是
虚构串或缺语义。

## 原版证据链

| 层 | 原版类 | 语义 |
|----|--------|------|
| 图标钮 | `mf2` case21 | `i87.b(hamburger, ui_librarypane__cd_organize)` → "Organize" |
| 锚点 | `ihm.a` | `wv9.b(t0c.R=COMPACT_ORGANIZE, 槽位2)` 包该钮；宿主 `l86`/`vkm` |
| 抽屉 | `fla`/`cla` | ModalDrawer 遮罩 `tuf.b` 语义=close_drawer + `nfh.b` 点击关闭 |
| 对话框 | `ybn` | 名称框语义=cd_folder_name；check 确认钮 cd=cd_confirm="Save folder" |

## Harmony 实现

1. 新增 `ui_librarypane__cd_organize`/`close_drawer`/
   `ui_folder__cd_folder_name`/`ui_folder__cd_confirm`（en 逐字 +
   zh 本地化：整理/关闭导航菜单/文件夹名称/保存文件夹）。
2. `LibraryPage`：
   - hamburger 钮 cd `open_folder_drawer` → `cd_organize`；
   - 文件夹名钮移除虚构覆盖，回到以当前文件夹名自标识；
   - 抽屉遮罩 Column 补 `accessibilityText(close_drawer)`；
   - 文件夹对话框名称 `TextInput` 补 `cd_folder_name`，确认钮补
     `cd_confirm`（保留 "Confirm" 视觉，a11y 宣告 "Save folder"）。
3. 删除虚构串 `open_folder_drawer`（en/zh，已无引用）。

## 校验

- 本 Phase Replay：16/16 全绿。
- 全量 Desktop Replay：1268/1268 全绿（新增 + re-anchor）。
- `note@default` HAP 构建通过；clean `note@ohosTest` 构建通过。

## 遗留

- 文件夹对话框原版确认钮为 check 图标（`general_check_med_bold`），
  Harmony 保留文本钮形式、a11y 对齐 —— 视觉差异属既有样式选择。
