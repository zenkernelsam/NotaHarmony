# Phase 1430：文件夹 emoji 选择器全数据集 + 搜索补齐报告

- 日期：2026-08-09
- 状态：完成
- 证据：`docs/migration/evidence/phase-1430-folder-emoji-picker.md`
- 决策：`docs/migration/adr/ADR-1365-folder-emoji-picker-search.md`
- Replay：`docs/migration/replays/d02-original-folder-emoji-picker.mjs`（13 项）

## 缺口

原版文件夹装饰 emoji 选择器（`el4`）= 搜索框 + `ok4` 九类分区网格 +
`emojis_unicode.json` 全量数据集（1913 枚，随包资产）。Harmony 仅有
九类策划子集（~180 枚），无搜索。

## 实施

- `rawfile/emojis_unicode.json` 逐字打包（原版资产等价先例）。
- 新 `FolderEmojiDataset.ets`：`getFolderEmojiSections`（rawfile +
  utf-8 + JSON.parse → `ok4` 序分区，缓存）+ `filterFolderEmojiSections`
  （`el4` 谓词逐字等价：emoji/description/aliases/tags contains-ci，
  空分区剔除）。
- `NameDialog`：emoji 页签顶部搜索框（placeholder/clear 钮 +
  a11y），非空查询 → 分区结果（类别头）或 `no_results`；空查询 →
  图标条 + 全集分区网格（策划子集改为加载占位）。
- 新键 ×3 en 逐字 + zh 补写。
- 呈现差异：图标条为切分区（原版滚动锚点）——同类别同数据，
  登记 ADR-1365。

## 验证

- fixture 13/13；Desktop Replay 基线与双 HAP 构建见本 Phase 验收。
