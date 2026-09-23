# 证据：原版 .note 录音实体随同步 ops 往返（yk9/zl8）

- 日期：2026-09-28；Phase 627
- 原版来源：`decompiled_1.0.3/sources/defpackage/yk9.java`、
  `zl8.java`、`cl9.java`、`zq6.java`
- Harmony 实现：`note/src/main/ets/data/NotePackageSpec.ets`、
  `NoteExporter.ets`、`NoteImporter.ets`、
  `OriginalRecordingOperation.ets`

## 原版 .note 的录音实体通道（yk9.java）

原版 `.note` 包的四个顶层条目：`version`、`manifest.json`、
`noteBundle`（flatbuffer 同步 op 流）、`assets/<hash>[.<ext>]`。
录音**实体**随 `noteBundle` 内的 CREATE_RECORDING op 序列化
（yk9.java:160-215：`(z || uq9Var.m() != haa.CREATE_RECORDING)`
——`z`=`yk9.O`，分享层 includeRecordings 开关透传；
`haa.CREATE_RECORDING` 序号 5），录音**字节**则进
`assets/<ug5.e(ba6.e0(ua0))>` 内容寻址集合（Phase 626 证据）。

## 原版导入端（zl8/cl9）

`zl8`/`cl9` 是 .note/.ntb 导入协程：读 `noteBundle` op 流重放，
CREATE_RECORDING op 重建录音实体行并挂资产引用；
`assets/<hash>` 条目按 `zq6.h`（zq6.java:157-160
=`assets/final/<hash>`）内容寻址落盘，`ua0` 即内容哈希——
实体与字节按哈希重联，录音行重新解析为可播放。

## Harmony 缺口（Phase 626 之后）

- `NoteExporter` 已把录音字节并入 `assets/`（Phase 626），
  但包内**没有任何录音实体序列化**（Harmony 格式无 ops 流）；
- `NoteImporter.importOurFormat` 只按页元数据收集图片/PDF
  资产，`original_recording_state` 行零恢复；
- `importNotability`（外部格式）对 `Recordings/` 条目仅计数
  `session.inventory.audio.found`，不恢复实体——故原版包的
  录音在 Harmony 侧导入即丢，本端包再导入同样丢。

## Harmony 落地（本 Phase）

- `NotePackageSpec` 新增 `recordings.json`（version=1）：
  `PackagedRecording { timestamp, siteId, name, startTime,
  endTime, segments[], zIndex, assetHashBits[8], assetFileName,
  assetMimeType, assetFileSize }`——与
  `original_recording_state` 列一一对应；
- 校验与原版 `yn2.a` CREATE_RECORDING 解码同界：
  `startTime ≤ endTime`、段仅校验 `segment.endTime ≤
  endTime` 一侧、zIndex/start/end/段/哈希词全部走
  `validateUnsignedLongDecimal`、hashBits 恰 8 词、
  `fileSize ∈ [1, 2^32-1]`、timestamp u32 / siteId u16；
- `NoteExporter`：`listVisible` 录音全部写清单（无
  `yk9.O` 等价开关——Harmony 导出恒含录音，与 Phase 626
  一致）；字节已由既有 `assets/` 循环覆盖；
- `NoteImporter.importOurFormat`：找 `recordings.json` →
  `parsePackagedRecordings`；每条录音的资产并入同一
  `declaredAssets`/`packagedAssets` 簿记（冲突元数据 →
  CORRUPTED；条目缺失/长度不符 → `missingAssetPaths`）；

- 写库阶段先经 `insertImportedOriginalRecording`（
  `OriginalRecordingOperation`）按 `applyCreate` 同列集插
  `original_recording_state` 行 + `mergeOriginalAssetReference`
  建 PENDING `note_asset`，再由既有
  `storeImportedOriginalAsset` 循环升级 LOCAL——实体先于
  字节落库，资产引用链路等价原版 op 重放；
- `createNoteWithMeta` 的 `hasRecordings` 由清单长度驱动，
  `refreshOriginalRecordingPresence` 兜底一致。

## Fail-closed 边界

- `recordings.json` 存在但解析失败 → 整个包 CORRUPTED
  （与 manifest/page 校验同级，不静默丢录音）；
- 录音资产元数据与页面/PDF 声明冲突 → CORRUPTED；
- 录音行身份冲突（同 noteId+timestamp+siteId 异签名）→
  抛错 → 外层 catch 走 `removeFailedImport` 清理；
- 录音资产字节缺失 → 行已建、资产行留 PENDING →
  `listVisible` 返回 PENDING/MISSING 态（录音可见、音频
  待补），与图片/PDF 缺资产的 fail-soft 一致；
- 无 `recordings.json` 的旧版 Harmony 包照常导入（清单
  可缺省，向后兼容）。
