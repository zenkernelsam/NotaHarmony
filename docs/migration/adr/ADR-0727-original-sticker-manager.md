# ADR-0727 — 原版 1.4.2 贴纸管理器面与纸模板分类法登记

日期：2026-09-29
状态：已登记（版本差·本地/边界分层；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-783-original-sticker-manager.md`
Replay：`docs/migration/replays/d02-original-sticker-manager.mjs`
上游：ADR-0713（stickers.apk）、ADR-0714（下载 Worker）、ADR-0708

## 背景

`feature_note_stickers__*` 70 键构成完整贴纸管理器：
四页签（All/Favorites/My Stickers/Recents）、自建贴纸
（笔迹→选择菜单→贴纸）、长按收藏、删除跨设备提示、
约 40 具名包与商店下载入口；`ui_papertemplates__*` 五类目
为 35 包目录分组法。

## 决策

1. **自建贴纸 + 收藏/最近/插入**：版本差·本地候选——
   笔迹转贴纸为纯本地数据流，可移植性高。
2. **商店包下载 / 跨设备同步**：PAD/CDN + 账号后端，
   fail-closed 随既有贴纸边界族。
3. 五类目法登记为模板目录组织键。
4. 本阶段不实现。

## 后果

- 贴纸族三层（资产/Worker/管理器 UI）登记闭合。
- 自建贴纸语义（选择菜单入口）进入 T-042 输入。
