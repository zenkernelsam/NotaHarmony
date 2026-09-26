# Phase 855 报告：分享 ZIP 契约还原与移植补齐

## 范围

Phase 849 遗留的「x59 分享 ZIP」暂缓史诗：原版
PDF+include_recording 分享产物的容器格式与接线缺口。

## 原版证据

- 写出器：1.0.3 `x59` / 1.4.2 `x8b`（同体，混淆重排）；
  上游编排 `yk9`（`zk9.a→yk9.O` 开关位）。
- 契约：`<title>.zip` = `<title>.pdf`（可选 `wba.d` 密码加密）
  + `Recordings/<j0.m(name)>.<ext>`；重名 ` (N)` 自 1 起；
  `MimeTypeMap` 取扩展名回退 `"mp4"`；缺失文件条目跳过；
  空录音列表早退裸 PDF。
- `j0.m` 消毒：`[/\\:*?"<>|\x00]`→`_`、剥前导 `.`、
  空回退 `"Note"`。

## 修复前缺陷

`EditorToolbar` pdf 分支渲染了录音开关，但 `dispatchShare`
调 `onSharePdf` 时丢弃 `shareIncludeRecording`；多选分享
PDF 分支同病。**死开关缺陷**。

## 落码

- `PagePdfExporter.exportPdfZip` + `PdfZipRecordingSource`；
  `shareEntryName`/`shareZipExtension`/`readFileFully` 导出。
- `EditorToolbar`/`NotePage`/`LibraryPage` 三处接线；
  多选逐笔记产 zip。
- 修复中顺手发现并规避一次字节级事故：补丁向 regex 字面量
  写入裸 NUL（已转义为 `\x00`，LF 行尾保持）。

## 验证

- Replay `d02-share-zip-recordings.mjs`：**23/23**。
- 全套 Replay：**726/726**；双 HAP clean。
- ADR-0799。**分享面缺口闭合。**
