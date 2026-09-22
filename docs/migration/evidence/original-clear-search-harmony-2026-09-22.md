# 原版搜索清空按钮 → HarmonyOS 移植证据（2026-09-22）

## 原版证据

- `decompiled_1.0.3/sources/defpackage/nb7.java`：`qoeVar.d().K.length() > 0` 时
  挂载 `mb7`——28dp 清除图标按钮，content description 为
  `feature_library__clear_search`（"Clear search"），点击清空查询。
- `decompiled_1.0.3/sources/defpackage/mb7.java`：`go5.b(ue4.u(...), clear_search,
  28dp padding, onClear)`。
- `strings.xml`：`feature_library__clear_search` = "Clear search"。

## Harmony 移植

- `LibraryPage` 搜索 `TextInput` 增加 `.cancelButton({ style:
  CancelButtonStyle.INPUT })`：输入非空时显示原生 X 按钮，点击清空文本并触发
  `onChange('')`，走既有防抖 `setSearchQuery('')` 重载管线。
- 与原版一致：仅在有查询内容时可清除；清除后立即恢复未过滤列表。
- 差异登记：Harmony 原生 cancelButton 无独立无障碍标签且仅在输入态显示，
  原版为常态图标按钮；语义等价，属平台适配。

## 验证

- 回放 `docs/migration/replays/d02-original-clear-search.mjs`：原版门控/按钮/
  字符串锚点 + Harmony cancelButton 与重载管线锚点，全过。
- `note@default`、`note@ohosTest` 双构建通过。
