# 证据：原版 .note 导出把录音音频并入 assets/（yk9）

- 日期：2026-09-28；Phase 626（含同 Phase 内 x59→yk9 纠正）
- 原版来源：`decompiled_1.0.3/sources/defpackage/yk9.java`、
  `zk9.java`、`y59.java`、`x59.java`、`haa.java`
- Harmony 实现：`note/src/main/ets/data/NoteExporter.ets`

## 原版 .note 包结构（yk9.java:253-296）

`yk9.invokeSuspend` 写出真正的 .note zip：

1. `version` → 字节 `"1"`；
2. `manifest.json` → `cx7` 序列化清单；
3. `noteBundle` → flatbuffer 同步 op 流；
4. `assets/<ug5.e(ba6.e0(ua0))>[.<ext>]` —— 逐项写出
   `note.assets`（`mx7VarB`）中的**全部**资产；扩展名来自
   `MimeTypeMap.getExtensionFromMimeType(wa0.m())`，为 null 时
   **不带扩展名**（无 mp4 兜底——那是 x59 的语义）。

## 录音如何进入 note.assets（yk9.java:160-215）

op 迭代门：
`uq9Var.r(sdfVar) == null && (z || uq9Var.m() != haa.CREATE_RECORDING)`
——`z`（=`yk9.O`，由 `zk9.a(...)` 布尔入参透传，分享层的
"包含录音"开关）为假时 CREATE_RECORDING op 被整体跳过（不进
noteBundle、也不进资产收集）。`haa.CREATE_RECORDING` 序号为 5
（haa.java:23），在资产收集 switch 的 `iOrdinal == 5` 分支经
`kaj.a(yn2)` 产出 `cba`，其 `a().j()` 的 ua0 被 put 进
`mx7`（:212-213）——**录音音频就是普通内容寻址资产**。

## 缺失资产 fail-hard（yk9.java:242-252）

收集完成后逐项检查 `zq6.h(context, ua0).exists()`；任一缺失 →
`throw new MissingAssetsException(arrayList3)`，整个导出中止。
`zq6.h`（zq6.java:157-160）= `assets/final/<ug5.e(ba6.e0(ua0))>`
——内容寻址文件名。

## x59 是 ZIP 分享格式而非 .note（x59.java:480-526）

`x59` 输出 `<名>.zip`（`vh2.o(str2, ".zip")`，:480），内含
`<名>.pdf` + `Recordings/<j0.m(name)>.<ext>`（j0.m 净化 +
MimeTypeMap 扩展名 null→"mp4" + ` (n)` 去重 + exists() 静默跳过）。
且 `listT1.isEmpty()` 时直接返回裸 PDF（:477-479）——**没有
录音时连 zip 都不产生**。该格式属分享 epic，不进 .note 包。

## Harmony 落地（NoteExporter.ets）

- `OriginalRecordingStore.listVisible(noteId)` 取可见录音，
  每条把 `{assetHashBits, assetFileName, assetMimeType,
  assetFileSize}` `addAsset` 进既有 `assets` 图；
- 包内条目名 = `originalAssetPackageEntry` =
  `assets/<originalAssetStorageHash(hashBits)>` —— 与图片/PDF
  同一内容寻址约定，同构原版 `assets/<hash>`；
- `addAsset` 对同路径冲突元数据抛错（`asset metadata
  conflicts`），写循环 `resolveOriginalAsset === null` →
  `throw` —— 即 MissingAssetsException 等价 fail-closed；
- Harmony 导出单路径恒含录音（等价 `yk9.O=true`）。

## 静态差异（记录在案）

- 原版资产条目可带 `.<ext>` 后缀；Harmony 既有
  `originalAssetPackageEntry` 为无扩展名 `assets/<hash>`，
  导入按键名哈希解析，扩展名仅装饰性——保持一致未加。
- Harmony .note 包不序列化录音实体本身（无 noteBundle/op 流），
  本端再导入时录音行不恢复——属后续 Phase（实体序列化）范围；
  本 Phase 只保证资产字节不丢。
