# Phase 545 — 原版新建笔记快捷动作（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/library/LibraryPage.ets`、`NotePage.ets`、
`NoteImporter.ets`、`BackupPage.ets`、双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

`ksh.g` 渲染库内新建卡片（标题/副标题/图标 + `t6j.b` FAB），FAB 展开
内容为 `mw3` case 0 的快捷动作行（`p40.b(icon, label, callback)`，
固定序）：

1. `empty_note__record_audio` + `record_mic_outline` — `sc(function0,
   function1)` 组合回调（收起 + 启动录音建笔记）。
2. `empty_note__import_file` + `import_new_note` — 文件导入。
3. `empty_note__scan` + `docscan` — 仅 `z2`（设备扫描能力）时渲染。
4. `empty_note__capture_and_add` + `capture_screen_content` — 仅
   `function4` 非空时渲染。

`oi5`/`wi5` 确认卡片本体点击（`vo2` 回调）= 该卡片的默认建笔记动作；
FAB 展开项是附加创作入口。

## Harmony 落地

`LibraryPage`：

- FAB 由"直接建空白笔记"改为 speed-dial：`createMenuOpen` 状态，
  "+" 点击展开/收起（图标 +/× 切换）；展开列出
  **New note → Record audio → Import file**（原版动作序；卡片本体的
  空白创建以首项等价承载）。
- `createAndRecord` → `createAndLaunch(true)`：建笔记后以
  `params: { noteId, autoRecord: '1' }` 打开编辑器。
- `importAndOpen`：`NoteImporter.importFromFile`（系统文档选择器，
  .note 过滤）→ 成功 `loadNotes` 刷新后打开导入笔记；取消静默、
  失败 toast `import_failed`。生命周期/活跃守卫与 createAndLaunch
  同款。

`NotePage`：`aboutToAppear` 读 `params['autoRecord']`；`loadPages`
  成功路径末尾（`loadRecordings` 之后）若请求则
  `showRecordings = true` + `startRecording()`（沿用既有麦克风/
  内录源选择交互）。

`NoteImporter`：`ImportResult` 新增 `CANCELLED`（picker 空选）；
`BackupPage` 对 CANCELLED 静默（原行为会把取消误报为"导入失败"）。

## 差异登记

- scan（docscan 扫描能力）与 capture_and_add（截屏捕获）无可移植
  后端——登记。
- 原版动作为卡片内嵌 FAB 展开；Harmony 为全局唯一创建 FAB 的
  speed-dial 展开——形态等价、归属面不同（登记）。
- autoRecord 经路由参数传递；编辑器在加载完成后直接进入采集。
