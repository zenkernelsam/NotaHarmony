# ADR-0595: .note 导出把录音音频并入 assets/（yk9 语义）

- 状态：已接受
- 日期：2026-09-28；Phase 626
- 证据：`docs/migration/evidence/original-export-recordings-2026-09-28.md`

## 背景

初版调查把 `x59` 的 `Recordings/<j0.m(name)>.<ext>` 误当成
.note 导出语义；复审发现 x59 产的是 `<名>.zip` **分享包**
（`vh2.o(str2,".zip")`，无录音时直接返回裸 PDF）。真正的
.note 导出器是 `yk9`：`{version, manifest.json, noteBundle,
assets/<内容哈希>[.<ext>]}`——录音音频经 CREATE_RECORDING op
的 ua0 进入 `note.assets`，与图片/PDF 同一内容寻址布局；
声明资产文件缺失 → `MissingAssetsException` 中止导出。

Harmony `NoteExporter` 此前只收集图片/PDF 资产，录音字节
在导出包中整体丢失。

## 决策

1. 录音资产**并入既有 assets 图**而非另起 Recordings/ 目录：
   `listVisible(noteId)` 逐条 `addAsset({assetHashBits,
   assetFileName, assetMimeType, assetFileSize})`，包内条目
   `assets/<sha512>` 与元素/PDF 资产同约定——同构 yk9 的
   `assets/<ug5.e(ba6.e0(ua0))>[.<ext>]`。
2. 共享写循环天然给出原版语义：同哈希冲突元数据 →
   `addAsset` 抛错；资产不可解析 → `resolveOriginalAsset`
   null → `throw` 中止导出（MissingAssetsException 等价）。
3. 不设独立的录音开关：`yk9.O` 是分享层 "includeRecordings"
   选项，Harmony 单导出路径恒含录音（=O 恒真）。
4. `Recordings/<净化名>.<ext>` + j0.m 净化 + ` (n)` 去重 +
   mp4 兜底属 `x59` ZIP 分享格式，归分享 epic，不进 .note。

## 已知边界（fail-closed）

- Harmony .note 不序列化录音实体（无 noteBundle）：资产字节
  随包走，但再导入时录音行不恢复。实体级往返属后续 Phase。
- 原版条目可带 `.<ext>`；Harmony 既有包约定为无扩展名
  `assets/<hash>`（导入按键名解析），保持一致。
- 非 READY 录音（资产行缺失/PENDING/FAILED）触发导出中止 —
  与图片/PDF 资产的既有 fail-closed 一致，强于 x59 的
  exists() 静默跳过（x59 语义不适用于 .note）。

## 影响

- `note/src/main/ets/data/NoteExporter.ets`：导出循环前追加
  `listVisible` + `addAsset`；无新增 helper。
- `docs/migration/replays/d02-original-export-recordings.mjs`：
  yk9 包结构/开关/fail-hard 证据 + x59 边界锚点 + Harmony
  实现锚点 + addAsset 冲突去重模拟（25 断言）。
