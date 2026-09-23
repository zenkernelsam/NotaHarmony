# Phase 626 — .note 导出把录音音频并入 assets/（yk9）

## 原版证据

- `yk9.java:253-296`：.note = zip{`version`="1",
  `manifest.json`(cx7), `noteBundle`(op 流),
  `assets/<ug5.e(ba6.e0(ua0))>[.<ext>]`} —— 资产按内容哈希
  入包；`MimeTypeMap` 扩展名为 null 时不带后缀（无 mp4 兜底）。
- `yk9.java:162`：`(z || type != CREATE_RECORDING)`——
  `yk9.O`（`zk9.a(...)` 布尔入参，分享层"包含录音"开关）
  为假时录音 op 不进 noteBundle 也不进资产收集。
- `yk9.java:212-213`：CREATE_RECORDING（haa 序号 5）经
  `kaj.a(yn2).j()` 把录音 ua0 put 进 note.assets。
- `yk9.java:242-252`：`zq6.h(ua0).exists()` 缺失 →
  `MissingAssetsException` 中止导出。
- `x59.java:477-526`：`Recordings/<j0.m(name)>.<ext>` 属于
  `<名>.zip` 分享格式（无录音时返回裸 PDF），与 .note 无关。

## 排查结论

Phase 626 初版把 x59 的 Recordings/ 误当 .note 语义；yk9 证据
表明录音音频应作为普通内容寻址资产入 assets/。Harmony
`NoteExporter` 的 assets 图本就覆盖图片/PDF，录音只需并入。

## 修复

- `NoteExporter.ets`：资产写循环前 `listVisible(noteId)`，
  每条可见录音 `addAsset({assetHashBits, assetFileName,
  assetMimeType, assetFileSize})` 入图；冲突/缺失由既有
  fail-closed 路径承担（= MissingAssetsException）。
- 移除初版误加的 j0.m 净化/mime→ext 表/" (n)" 去重 helper
  ——均属 x59 分享格式语义。

## 回归验证

- `d02-original-export-recordings.mjs`：yk9 结构/开关/
  fail-hard + x59 边界 + Harmony 锚点 + addAsset 模拟 →
  25/25 PASS。
- 全量 Desktop Replay：515/515 PASS。
- `note@default` + `note@ohosTest` HAP 构建成功。

## 文件

- `note/src/main/ets/data/NoteExporter.ets`
- `docs/migration/replays/d02-original-export-recordings.mjs`
- `docs/migration/evidence/original-export-recordings-2026-09-28.md`
- `docs/migration/adr/ADR-0595-original-export-recordings.md`
- `docs/migration/reports/phase-626-original-export-recordings.md`
