# Phase 1339 证据 — 库页 + 设置 UI

来源：`ui/library/{LibraryPage,LibraryViewModel}.ets`+
`ui/settings/`（5 页）。

## `LibraryPage` 原版保真细节

```
// 原版文件夹自定义：e47 SyncedFolderMetadata.color/emoji
//   + 1.0.3 文件夹对话框
// 原版调色板常量未反编译 → 文档化近似配色
// 原版 emoji 选择器 = LIBRARY_FOLDER_EMOJI_PICKER flag +
//   du3 九类分类网格 → Harmony 按原版分类序提供策划
//   子集；空串 = 无 emoji（pdb.d() 等价）
// 原版 ML Kit 扫描页数上限未解出 → Harmony 文档化上限
// ie7 视图模式（z97 pref，默认 GRID）：grid 卡片 vs
//   紧凑列表行（yj9 按 ie7.ordinal() 选 b5j.b/m5j.b）
@State listView —— grid/list 切换
```

→ 库页逐项对照原版语义，未反编译处显式文档化近似
（调色板/emoji 子集按原序/ML-Kit 上限）—— 诚实
记录不可恢复细节而非臆造。

## `ui/settings` 5 页

`SettingsPage`/`BackupPage`/`WebDAVSettingsPage`/
`DefaultTemplatePage`/`RecentlyDeletedPage` —— 设置/
备份/WebDAV/默认模板/最近删除。

## Harmony 决策

库页 = grid/list（`ie7` 默认 GRID）+文件夹 emoji/color
（`e47`/`du3`/`pdb.d` 语义）；设置 5 页 —— 原版语义
保真，未反编译资源显式近似。

## 产出

- fixture `d02-library-ui.mjs`（10 断言）。
- ADR-1282；中文报告。
