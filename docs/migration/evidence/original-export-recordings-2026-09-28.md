# 证据：原版 .note 导出携带 Recordings/ 音频条目（x59/j0.m）

- 日期：2026-09-28；Phase 626
- 原版来源：`decompiled_1.0.3/sources/defpackage/x59.java`、
  `j0.java`、`oj3.java`
- Harmony 实现：`note/src/main/ets/data/NoteExporter.ets`

## 原版行为（x59.java:490-526）

`.note` 导出在写完 PDF 条目后，对每条可见录音写一个 zip
条目：

1. **可见性过滤**：`listT1` 来自 `!aa6.V(qo5, x09)` 过滤
   （x59.java:507-515）——被隐藏的录音不导出，等价 Harmony
   `OriginalRecordingStore.listVisible`。
2. **文件存在性**：`zq6.h(context, yjbVar.H())` 按录音资产
   哈希解析本地文件；`fileH.exists()`（:496）为假则**静默
   跳过**，不中止导出。
3. **扩展名**：`MimeTypeMap.getSingleton()
   .getExtensionFromMimeType(yjbVar.x().j().m())`（:497）；
   返回 null 时兜底 `"mp4"`（:498-500）。
4. **条目名净化**：`j0.m(yjbVar.getName())`（:501）。
5. **条目路径**：`"Recordings/" + 净化名 + "." + ext`
   （:503-509，str6="Recordings/"）。
6. **重名去重**：`LinkedHashSet` 收集已用名；
   `!linkedHashSet.add(string)` 时改写为
   `Recordings/<名> (n).<ext>`，`r11` 自 1 起递增
   （:510-513；r11 槽位承接 `z2=true`，JVM 中即 1）。
7. **内容**：`FileInputStream` 原样流拷贝（:514-518）。

## 净化规则（j0.java:42-64）

`j0.m(String)`：

- null → ""；
- `Pattern.compile("[/\\\\:*?\"<>|\\\\x00]")` 命中的字符
  全部替换为 `_`（即 `/ \ : * ? " < > | \x00`）；
- 从头剥掉连续的 `.`（`char[]{'.'}` 前导扫描）；
- 结果为空 → `"Note"`。

注意它与 Harmony 既有的 `safeFileName`（导出 PDF 文件名用，
trim + 非法字符剔除 + 兜底 `note`）是**两套不同规则**——
j0.m 不 trim、保留内部空格、替换而非删除。

## 音频 mime 域（oj3.java:32）

原版识别的录音 mime 集合为 `{mp3, mp4, aac, wav, aiff,
m4a}`（`nj3` 枚举）。`MimeTypeMap` 是 Android 平台映射表，
Harmony 侧无对应系统 API，故以等值映射表落地：覆盖
audio/mp4、x-m4a、mp4a-latm、aac、aacp、adts、mpeg、mp3、
wav、x-wav、wave、aiff、x-aiff、3gpp、amr、ogg、flac；
其余一律回退 `mp4`，与原版 null 兜底一致。

## Harmony 落地（NoteExporter.ets）

- 页面/图片/PDF 条目写完后，追加
  `OriginalRecordingStore.listVisible(noteId)` 循环；
- 每条录音先查 `assetState !== READY` → 跳过（等价
  `fileH.exists()` 的 fail-soft），再
  `resolveOriginalAsset` 解析资产、`asset === null` →
  跳过；
- `readVerifiedOriginalAsset` 校验后写入，保证坏资产不进
  包（强于原版的裸流拷贝，属 fail-closed 加固）；
- `sanitizeOriginalRecordingEntryName` 逐条对齐 j0.m；
- `originalRecordingExportExtension` 为 mime→ext 等值表 +
  `mp4` 兜底；
- `usedRecordingEntries` Set 去重，`dedupeIndex` 自 1 起，
  生成 `名 (n)` 后缀——与原版 `linkedHashSet` + `r11`
  逐项同构。

## 静态差异（记录在案）

- 原版循环内 `apb.w(hi2Var.U())` 是协程活性检查；Harmony
  导出为同步实现，无等价物。
- 原版对不存在的文件只查 `exists()`，不校验内容；Harmony
  经 `readVerifiedOriginalAsset` 读校验字节——对损坏资产
  更严格（fail-closed）。
