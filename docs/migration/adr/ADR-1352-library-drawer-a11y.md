# ADR-1352 窄屏库 chrome 与文件夹对话框无障碍语义

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1416
- 接续：ADR-1351（onboarding 链收尾后暴露的窄屏库 chrome a11y 差距）
- 证据：`docs/migration/evidence/phase-1416-library-drawer-a11y.md`

## 背景

窄屏库 chrome 的无障碍与原版存在三处偏差：

1. **hamburger 钮 cd**：原版 `mf2` case21 →
   `i87.b(hamburger_icon, ui_librarypane__cd_organize)`，cd =
   "Organize"；`ihm.a` 经 `wv9.b(t0c.R, 2)` 把它包成 COMPACT_ORGANIZE
   引导锚点。Harmony 此前挂了虚构串 `open_folder_drawer`。
2. **遮罩 cd**：原版 `fla` ModalDrawer 遮罩经
   `tuf.b(semantics)` 挂 `close_drawer`="Close navigation menu" +
   `nfh.b` 点击关闭；Harmony 遮罩有点击关闭但无语义。
3. **文件夹对话框**：原版 `ybn` 名称框语义 =
   `ui_folder__cd_folder_name`，check 图标确认钮 cd =
   `ui_folder__cd_confirm`("Save folder")；Harmony 两者皆无专用 cd，
   确认钮宣告 "Confirm" 而非 "Save folder"。

## 决策

1. 新增四枚原版字串（en 逐字、zh 本地化）：
   `ui_librarypane__cd_organize` / `close_drawer` /
   `ui_folder__cd_folder_name` / `ui_folder__cd_confirm`。
2. `LibraryPage` 窄屏头部 hamburger 钮 cd 改挂 `cd_organize`；
   COMPACT_ORGANIZE `bindPopup` 锚点不变。
3. 文件夹名钮移除 `open_folder_drawer` 覆盖 —— 原版 `vkm` compact
   头部未见专用 cd，名钮以文本自标识。
4. 遮罩 Column 补 `accessibilityText(close_drawer)`。
5. 文件夹对话框 `TextInput` 补 `cd_folder_name`；确认 `Button` 补
   `cd_confirm`（保留 "Confirm" 文本视觉，a11y 宣告对齐原版
   "Save folder"）。
6. 删除虚构串 `open_folder_drawer`（en/zh）——本 Phase 后无引用，
   与 Phase 1412 `connect_action` 清理先例一致。

## 结果

无障碍语义与原版逐点对齐；可见 UI 不变（仅 a11y 宣告与语义词调整）。

## 验证

- Replay `d02-original-library-drawer-a11y.mjs`：16/16。
- `d02-original-compact-library-drawer.mjs` 旧 `open_folder_drawer`
  锚点重挂至 `cd_organize`/`close_drawer` 并断言虚构串已移除。
