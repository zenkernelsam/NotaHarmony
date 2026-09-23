# ADR-0595: .note 导出携带 Recordings/ 音频条目（x59/j0.m 语义）

- 状态：已接受
- 日期：2026-09-28；Phase 626
- 证据：`docs/migration/evidence/original-export-recordings-2026-09-28.md`

## 背景

原版 `x59.java:490-526` 在 `.note` zip 中、PDF 条目之后
逐条写入录音文件：`Recordings/<j0.m(name)>.<ext>`。
Harmony 已具备完整的录音采集/持久化/导入盘点/播放链路
（`OriginalRecordingStore` 等），但 `NoteExporter` 此前只
导出页面 JSON、图片与 PDF 资产——**录音在导出包中整体
丢失**，.note 往返（导出→原版/本端导入）会静默丢音频。

## 决策

1. 导出循环追加在图片/PDF 资产之后：
   `OriginalRecordingStore.listVisible(noteId)` 取可见录音
   ——等价原版 `!aa6.V` 隐藏过滤（x59.java:507-515）。
2. 每条录音：
   - `assetState !== READY` → 跳过；
   - `resolveOriginalAsset` 解析失败 → 跳过
     （等价 `fileH.exists()` 静默跳过，不中止导出）；
   - 通过 `readVerifiedOriginalAsset` 读校验字节写入
     ——比原版裸 `FileInputStream` 拷贝更严格（fail-closed）。
3. 条目名：`Recordings/` +
   `sanitizeOriginalRecordingEntryName(name)` +
   `.` + `originalRecordingExportExtension(mime)`；
   重名经 `usedRecordingEntries` Set 改写成
   `名 (n)`（n 自 1 起），逐项对齐原版
   `linkedHashSet` + `r11` 去重（x59.java:510-513）。
4. 净化规则独立实现，不复用 `safeFileName`：j0.m
   不 trim、非法字符**替换为 `_`**（而非删除）、剥前导点、
   空兜底 `"Note"`（大写）——与标题净化（trim + 剔除 +
   `note`）语义不同，强行复用会偏离原版 zip 条目名。
5. mime→ext 用等值映射表落地 Android `MimeTypeMap`
   （Harmony 无对应系统 API），未知 mime 一律 `mp4` 兜底。

## 已知边界（fail-closed）

- `MimeTypeMap` 映射表只覆盖 oj3 音频域及常见音频 mime；
  平台表未覆盖的 mime 在原版也会落到 `mp4` 兜底，行为
  一致。
- 原版对损坏资产不校验即拷贝；Harmony 经
  `readVerifiedOriginalAsset` 校验，损坏资产会抛错中止
  导出（而非产出一个含坏文件的包）——有意收紧。
- 导出文件名前缀 `<j0.m(笔记名)>.zip`、PDF 条目名
  `<名>.pdf` 沿用既有实现，本阶段不改。

## 影响

- `note/src/main/ets/data/NoteExporter.ets`：新增录音导出
  循环 + `sanitizeOriginalRecordingEntryName` +
  `originalRecordingExportExtension`。
- `docs/migration/replays/d02-original-export-recordings.mjs`：
  新增——锚定 x59/j0 源码证据 + Harmony 实现锚点 +
  净化/扩展名/去重规则模拟（29 断言）。
