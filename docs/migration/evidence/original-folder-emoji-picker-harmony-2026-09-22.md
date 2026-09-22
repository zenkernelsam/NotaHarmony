# Phase 540 — 原版文件夹装饰页签与分类 Emoji 选择器（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/library/LibraryPage.ets`（`NameDialog` + 文件夹行）、
双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

- `ac4.java:133` + `msb.java`：`LIBRARY_FOLDER_EMOJI_PICKER` 特性开关
  （`androidFolderEmojiPicker`）。
- `hq4.java`：文件夹装饰枚举 `Color(ui_folder__decoration_color)` /
  `Emoji(ui_folder__decoration_emoji)`——装饰为二选一模型。
- `gaj.java`（文件夹新建/重命名对话框）：
  - 初态页签 `fsi.T((!flag || emoji==null) ? hq4.Color : hq4.Emoji)`——
    已有 emoji 时落在 Emoji 页。
  - flag 开启时渲染 `e(hq4, callback)` 页签行（`q31` 遍历 `hq4.M`）。
  - 内容按 `ordinal()` 切换：Color(0) → `d(6,...)` 六列色板；
    Emoji(1) → `a(count,...)` 分类 emoji 网格。
- `wm2.java` case 0（页签切换回调）：`hq4Var == hq4.Color →
  gl8Var2.setValue(null)`——切到 Color 页清空已选 emoji，随后
  `gl8Var.setValue(hq4Var)` 选定页签。**装饰互斥**。
- `du3.java`：九类枚举序 Smileys / PeopleBody / AnimalsNature /
  FoodDrink / Activities / Objects / TravelPlaces / Symbols / Flags。
- `md.java`：分类条图标 `ui_designsystem__emojis_{smiley,pawprint,
  food,basketball,lightbulb,car,numbers,flag}`。
- `ru3.java`：emoji 本体来自打包 Realm `EmojiInfo`（`emoji` 字段）——
  数据不在反编译产物中，不可恢复。
- `m6a.i(int)`/`m6a.h()`：分类索引选择 / 当前类网格计数（`xm2`）。

## Harmony 落地

`NameDialog`（LibraryPage.ets）：

- `@State decorationTab`（0=Color/1=Emoji）+ `@State emojiCategory`；
  `aboutToAppear` 以 `initialEmoji.length > 0` 落 Emoji 页（gaj.fsi.T 对齐）。
- `decorationTabButton`：分段页签行（q31 对齐）；点击 Color 页清空
  `selectedEmoji`（wm2 对齐——装饰互斥）。
- Color 页：既有 8 色调色板行不变。
- Emoji 页：`FOLDER_EMOJI_CATEGORY_ICONS` 分类条（9 项，du3 序）+
  ∅ 清除片 + `FOLDER_EMOJI_CATEGORIES[emojiCategory]` 七列网格
  （高 132 滚动区）。
- 文件夹行：emoji 优先渲染，未设时回落颜色点——与装饰互斥模型一致
  （原版行渲染未恢复，登记为推断项）。

## 验证

- `d02-original-folder-emoji-picker.mjs`：39 断言（du3 九类 / hq4 /
  wm2 / gaj / q31 / md / ru3 锚点 + Harmony 锚点 + 互斥语义可执行模型）。
- `d02-original-folder-customization-parity.mjs` 两处锚点合法演进：
  `FOLDER_EMOJI_PRESETS` → `FOLDER_EMOJI_CATEGORIES`。
- 全套 replay：435 PASS 0 FAIL。
- `note@default`、`note@ohosTest`：BUILD SUCCESSFUL。

## 登记差异

- 原版 emoji 全集存于打包 Realm `EmojiInfo`（约全量 Unicode）；
  Harmony 侧为每类 16–23 个策划子集。
- 原版分类条用矢量图标；Harmony 用代表 emoji 字形 + 类别名 a11y。
- 原版网格带搜索框（`ui_emojipicker__search_placeholder`）；搜索需
  逐 emoji 关键词数据，未移植——登记。
- 文件夹行 emoji/颜色并存显示改为 emoji 优先（推断项，与 wm2 互斥
  语义一致）。
