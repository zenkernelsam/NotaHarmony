# Phase 855 — 分享 ZIP 容器契约（PDF + Recordings/）与移植补齐

Phase 849 曾把「x59 分享 ZIP 格式」登记为暂缓史诗；本阶段完成
契约还原并在 Harmony 落地（单选/多选两条分享路径）。

## 原版证据

写出器类：1.0.3 `defpackage/x59.java`（559 行），1.4.2 混淆重排为
`defpackage/x8b.java`（538 行，同体）。上游分享编排 `yk9`
（`include_recording` → `zk9.a→yk9.O` 开关位）。

### 契约（x59 主体逆编）

```
1. 渲染笔记 → <safeTitle>.pdf（临时文件 file2）
2. password 非空 → wba.d() 对 PDF 施加打开密码（重写字节）
3. if (recordings.isEmpty()) → 直接返回 .pdf
4. else → <safeTitle>.zip：
     entry0: <safeTitle>.pdf
     entryN: Recordings/<j0.m(name)>.<MimeTypeMap ext|mp4>
     重名循环 → " (N)"（字节码 iconst_1 → N 自 1 起）
     fileH.exists()==false 的录音条目跳过（不阻断）
```

`j0.m` 消毒（1.0.3 `j0.java:42`）：`[/\\:*?"<>|\x00]` → `_`，
剥前导 `.`，空名回退 `"Note"`。`zq6.h(context, recId)` 解析
录音文件；`MimeTypeMap` 取扩展名，null → `"mp4"`。

## Harmony 状态（修复前缺陷）

- `EditorToolbar` pdf 分支存在 `share_include_recording` 开关行，
  但 `dispatchShare → onSharePdf(pageIndexes,password,
  includeBackground)` **丢弃 includeRecording**——开关为死位。
- `NoteExporter` 注释已正确预言该契约「x59 ZIP share format
  (deferred epic)」；`.note` 归档走 assets/ 不受其影响。
- 多选分享同病：`multiShare` PDF 分支忽略录音开关。

## 修复（本阶段落码）

- `PagePdfExporter.exportPdfZip()`：buildPdf→(可选)encryptPdfFile
  →ZipWriter `<title>.pdf` + `Recordings/<name>.<ext>`（` (N)`
  自 1、缺失文件跳过、mime→ext 含 audio/mp4→m4a、回退 mp4）
  →picker 保存 `.zip`。
- `shareEntryName`/`shareZipExtension`/`readFileFully` 导出复用。
- `onSharePdf` 签名补 `includeRecording`；`dispatchShare` 透传
  `shareIncludeRecording`；`shareNoteAsPdf` 经
  `OriginalRecordingStore.listVisible` 解析 → zip/裸 pdf 分支
  （空表按原版早退语义仍产裸 pdf——由 `recordings.length>0`
  判定）。
- `LibraryPage.multiShare` PDF 分支同契约：逐笔记
  includeRecording 开且有录音 → `<title>.zip` FILE 记录。

## 验证

- Replay `d02-share-zip-recordings.mjs`：**23/23**
  （双版本写出器证据 + 消毒规则 + Harmony 三处接线断言）。
- 全套 Replay 725→726；双 HAP clean。
- ADR-0799。
