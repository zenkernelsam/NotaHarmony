# ADR-0512 — 原版文件夹装饰页签与分类 Emoji 选择器

状态：Accepted（Phase 540）

## 背景

Phase 533 落地了 `folder.color`/`emoji` 与对话框编辑，遗留登记项：原版
emoji 选择器为 flag 门控（`LIBRARY_FOLDER_EMOJI_PICKER`）的分类网格，
Harmony 侧仅有 `∅`+10 预设行，且无原版的 Color|Emoji 装饰页签结构。

## 原版语义（证据）

- `hq4`：装饰枚举 Color|Emoji；`gaj` 对话框渲染页签行（`q31` 遍历
  `hq4.M`），内容按 ordinal 切换（Color→6 列色板 `d()`，Emoji→分类
  网格 `a()`）；初态 `emoji!=null → Emoji 页`（`fsi.T`）。
- `wm2`：切 Color 页清空 emoji——装饰互斥。
- `du3`：九类 Smileys…Flags；`md`：`emojis_*` 分类图标；`m6a` 持有
  选中类与计数。
- emoji 数据本体在打包 Realm `EmojiInfo`（`ru3`），不可恢复。

## 决策

1. `NameDialog` 增加 `decorationTab`/`emojiCategory` 状态；打开时
   `initialEmoji` 非空 → Emoji 页（gaj.fsi.T）。
2. 名称输入下渲染分段页签行；Color 页保留调色板，Emoji 页为九类
   分类条 + ∅ 片 + 七列网格（132 滚动高）。
3. 切 Color 页清 `selectedEmoji`（wm2）；emoji 提交语义不变
   （`normalizeFolderEmoji` 空→null）。
4. emoji 数据为每类 16–23 个策划子集（Realm `EmojiInfo` 不可恢复，
   登记）；分类图标用代表 emoji 字形（无 SymbolGlyph，登记）。
5. 文件夹行渲染改为 emoji 优先、否则色点（与互斥模型一致的推断项）。

## 后果

- 文件夹自定义交互与原版装饰模型对齐；搜索框与全量 emoji 数据未移植，
  登记为差异。
- `d02-original-folder-customization-parity.mjs` 两个锚点合法演进
  （PRESETS→CATEGORIES）。

## 验证

- `d02-original-folder-emoji-picker.mjs` 39/39；全套 replay 435/435；
  `note@default` + `note@ohosTest` BUILD SUCCESSFUL。
