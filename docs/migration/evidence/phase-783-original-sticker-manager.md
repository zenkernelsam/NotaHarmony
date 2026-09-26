# Phase 783 证据：原版 1.4.2 贴纸管理器面 + 纸模板分类法

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml（`feature_note_stickers__*`
70 键、`ui_papertemplates__*` 5 键、`ui_librarypane__*` 1 键）。
Replay：`docs/migration/replays/d02-original-sticker-manager.mjs`
ADR：`ADR-0727-original-sticker-manager.md`
上游：Phase 763（stickers.apk 资产）、Phase 770（下载 Worker）、
Phase 761（papertemplates 目录）

## 1. 贴纸管理器四页结构

- `all` / `favorites` / `my_stickers` / `recents` 四页签。
- **自建贴纸（本地候选核心）**：
  `empty_my_stickers_message` = "Select your ink, then tap %1$s
  in the selection menu to create a reusable sticker!"——
  用户可选中自己的笔迹→选择菜单生成可复用贴纸，
  **纯本地数据流**（笔迹→贴纸资产）。
- 收藏：长按+星标（`empty_favorites_message`）。
- 删除：`delete_message`="Deleted stickers are removed from
  all your devices."——跨设备同步提示（后端边界侧）。
- 商店：`pack_*` 约 40 个具名包（Abstract Backgrounds/
  At School/Back to School/Everyday 50/Teacher's Essentials/
  Essential Shapes/Patterned Washi/Planner-Dash 等）对应
  stickers.apk 的 webp 包；`download_pack`/`pack_download_failed`
  = 商店下载路径（Play Asset Delivery/CDN 边界）。

## 2. 纸模板分类法（ui_papertemplates__）

五类目键：`academic/creative/notepads/planning/self_care`——
对应 Phase 761 manifest.json 的 `category` 字段取值，
即 35 包目录的分组法。

## 3. 零散键

- `ui_librarypane__cd_organize`（Organize a11y）单键。

## 4. 分类结论

- **本地候选**：自建贴纸（笔迹→贴纸）、favorites/recents
  管理、insert——无后端依赖的编辑器内功能。
- **边界**：贴纸包商店下载（PAD/CDN）、删除跨设备同步。
- **数据登记**：五类目分类法为模板目录的组织键。
- Harmony 现状：无贴纸面；登记版本差。
