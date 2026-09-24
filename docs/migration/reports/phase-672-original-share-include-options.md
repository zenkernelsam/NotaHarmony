# Phase 672 — 原版分享面板结构重排 + 包含开关（v6d.i/v6d.j）

日期：2026-09-24
前置：Phase 671（`59918648`）

## 目标

把分享面板从"格式行点选即导出"迁移为原版 `dih` 的三段式
结构——格式 chip 行 + 按格式切换的选项区 + Cancel/Share
动作行——并落地 `v6d.i`（include background）与
`v6d.j`（include recording）两个包含开关。

## 原版行为（证据：dih/s6d/v6d/b7d/j6d/fw2/pj/strings）

- `dih` 主屏 = chip 行（`s6d` 五格式 LINK/PDF/NOTE/JPG/PNG）
  + 按 `v6d.c` 分派的选项区 + Cancel/Share 按钮；Share 标签
  随格式变化（`ui_share__action_*`）。
- 选项分派：PDF→`dih.h`（双开关+Page range+Password）；
  NOTE→`dih.d`（recording 开关）；JPG/PNG→`dih.a`
  （background 开关+Page range）；LINK→`dih.b`（权限行）。
- `v6d.i`=includeBackground（默认 false）、
  `v6d.j`=includeRecording（默认 true）；`j6d` Switch 绑定，
  `fw2` 渲染图标+标签，`pj` 分析事件消费三旗标。

## Harmony 实现

- `EditorToolbar.ets`：新增 `shareFormat`/`shareIncludeBackground`/
  `shareIncludeRecording` 状态；chip 行（LINK 置灰）；
  `ShareRangeRow`/`ShareToggleRow`/`SharePasswordRow` 选项组件；
  Cancel/`shareActionLabel()` 动作行；`dispatchShare()`。
- `ThumbnailRenderer.renderPageExport` 增 `exportBackground`
  形参：'paper'（含背景）/'white'/'transparent'（不含背景）。
- `NotePage`：三回调签名扩展；PDF 无背景填白（JPEG 无 alpha），
  JPG/PNG 无背景走 transparent；`shareNoteAsFile(includeRecording)`。
- `NoteExporter.exportToFile` 增 `includeRecordings`（默认 true，
  Library/Backup 旧调用点行为不变）。

## 校验

- 新增 `d05-original-share-include-options.mjs`：30/30。
- 更新六份存量分享 fixture（chip 化 + 新签名）：全绿。
- 全量 Desktop Replay：556/556。
- `note@ohosTest` / `note@default` clean 构建均成功。

## 遗留登记

- LINK chip 置灰（`dih.b` 账号域权限行无对应物）。
- 多笔记分享（`chip_*_multi`/`action_*_multi` + 库页多选
  分享入口）尚未迁移，继续登记。
