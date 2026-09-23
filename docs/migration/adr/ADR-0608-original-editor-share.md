# ADR-0608：原版编辑器右上角 Share 入口（NOTE 格式先行，其余格式 fail-closed）

- 状态：Accepted
- 日期：2026-09-23
- 阶段：Phase 641
- 证据：`docs/migration/evidence/original-editor-share-entry-jadx-2026-09-23.md`
- 关联：ADR-0507（拍照入口门禁先例）、库级 `export_note` 菜单（d5j Export）

## 背景

原版编辑器顶栏在 undo/redo 图标右侧渲染 Share 图标
（`x90.g` → `lc4.a(ac4.L)`，`ac4.L` = NOTE_SHARE，`zb4.L` PRODUCTION
档默认开启；`ke1` case 15 = `ui_designsystem__share` 图标 +
`toprighttoolbar_share_action` 无障碍）。点击打开分享面板
（`b7d`/`v6d`）：格式枚举 `s6d` = LINK、PDF、NOTE、JPG、PNG
（`atc` case 3~7 对应图标），单笔记默认选中 LINK。

Harmony 此前编辑器内没有任何分享/导出入口——`.note` 导出只存在于
库级上下文菜单（`LibraryPage.exportNote` → `NoteExporter.exportToFile`）。
用户在编辑器内无法导出当前笔记，属真实功能缺口。

## 备选方案

1. **完整复刻分享面板（21 字段 v6d：格式 chip + 页选择集合 +
   逐格式进度 + 系统分享 Intent）**：超出单 Phase 范围，且 PDF/JPG/PNG
   依赖尚不存在的页级栅格化器、LINK 依赖账号/链接后端——即使面板完整
   复刻，四个格式仍无法产出。
2. **Share 按钮直导 .note（不开面板）**：可工作但偏离原版"点 Share →
   选格式"的两步交互，且堵死后续格式扩展的 UI 位。
3. **入口 + 面板骨架先行（采用）**：Share 按钮按原版位置入顶栏，
   面板按 `s6d` 原序列出全部五格式；NOTE 行接既有
   `NoteExporter.exportToFile` 管线立即可用，其余格式置灰标注
   "暂不支持"。后续 Phase 接入页级栅格化器时逐行点亮。

## 决定

采用方案 3：

- `EditorToolbar` 在 Redo 按钮后渲染 48vp Share 按钮（原版位序），
  点击打开 `bindSheet` 分享面板；
- 面板按 LINK、PDF、NOTE、JPG、PNG 原序列行；NOTE 行可点，
  其余 `opacity 0.4` + "暂不支持"标注且点击空转（fail-closed，
  不产生半成品文件）；
- NOTE 行 → `NotePage.shareNoteAsFile()` →
  `NoteExporter.exportToFile(context, noteId, noteTitle)`：
  `.note` zip 包 + `DocumentViewPicker` 系统保存对话框 +
  `export_done`/`export_failed` toast（与库级导出完全同一管线）。

## 登记差异（fail-closed）

| 原版行为 | Harmony 现状 | 解锁条件 |
|----------|--------------|----------|
| LINK 分享链接（单笔记默认选中） | 行置灰 | 账号/链接后端（goal 外基础设施） |
| PDF 导出 | 行置灰 | 页级栅格化器 + PDF 编码器 |
| ~~JPG/PNG 导出~~ | ~~行置灰~~ → **Phase 642 已点亮**（当前页整页栅格化，ADR-0609） | ~~页级栅格化器~~ |
| 面板两步交互（chip 选择 + 动作按钮 + 页选择集合） | 单行即点即导 | 随栅格化格式落地一并补齐 |
| 安卓系统分享 Intent（v6d.t） | DocumentViewPicker 保存 | HarmonyOS 无同型组件；保存对话框为原生对等物 |

## 验证

- `docs/migration/replays/d05-original-editor-share.mjs`：41 断言
  钉死原版旗标/位序/格式序与 Harmony 实现/字符串。
- 全量 Desktop Replay 526/526；`note@ohosTest`/`note@default` 双 HAP
  clean 构建成功（见 Phase 641 报告）。

## 后续

- 页级栅格化器落地后：点亮 PDF/JPG/PNG 行，补面板两步交互与页选择。
- 若未来接入账号/链接后端：点亮 LINK 行并恢复单笔记默认选中 LINK。
