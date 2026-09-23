# Phase 627 — .note 录音实体往返（recordings.json 清单）

## 原版证据

- `yk9.java:160-215`：`.note` 经 `noteBundle` 同步 ops 序列化
  CREATE_RECORDING（`haa` 序号 5），`yk9.O`（分享层
  includeRecordings）为真时录音实体+资产同进包；
- `zl8.java`/`cl9.java`：导入端重放 ops 重建录音实体与
  `note_asset` 引用，`assets/<hash>` 字节按 `zq6.h`
  内容寻址落盘重联；
- `OriginalRecordingOperation.applyCreate`（Harmony 侧
  ops 重放实现，Phase 98）：插 `original_recording_state`
  行 + `mergeOriginalAssetReference` 建 PENDING 资产 +
  `refreshOriginalRecordingPresence`。

## Harmony 缺口

Phase 626 后 `.note` 只带录音**字节**（assets/ 集合），
实体不序列化——本端包再导入时 `original_recording_state`
零恢复，录音整体丢失。

## 决策与实现

新增 `recordings.json` 清单等价 ops 实体通道：

- `NotePackageSpec.ets`：`PackagedRecording`/`NOTE_RECORDINGS_ENTRY`
  + `serializePackagedRecordings`/`parsePackagedRecordings`，
  校验界与 `yn2.a` 同（段仅 `endTime ≤ 录音 endTime`）；
- `NoteExporter.ets`：`listVisible` 录音全量写清单
  （`recordings.length > 0` 时才写条目）；
- `NoteImporter.ets`：清单缺失容忍、损坏 CORRUPTED；
  每录音资产并入 `declaredAssets`/`packagedAssets`（冲突 →
  CORRUPTED；缺失 → missingAssetPaths）；写库阶段单事务
  调 `insertImportedOriginalRecording` 重建行，
  `createNoteWithMeta` 的 hasRecordings 由清单长度驱动；
- `OriginalRecordingOperation.ets`：新增
  `insertImportedOriginalRecording`——`applyCreate` 同列集
  （含 `create_*`/`name|segments|z_index` 值+胜者寄存器 +
  `create_signature`）+ `mergeOriginalAssetReference` +
  `refreshOriginalRecordingPresence`；
- 缺资产文案 `图片/PDF` → `图片/PDF/录音`。

## Fail-closed 边界

- `recordings.json` 损坏 → 整包 CORRUPTED；
- 录音/页面资产元数据冲突 → CORRUPTED；
- 录音行身份冲突 → 抛错 → `removeFailedImport` 清理；
- 录音字节缺失 → 行保留 PENDING（可见、音频待补）；
- 无清单旧包照常导入（向后兼容）。

## 验证

- 新 fixture `d03-original-import-recordings.mjs`：
  41 断言（yk9 证据、清单结构/校验界、导出落条目、
  导入 fail-closed 链、applyCreate 列集逐项等价、
  序列化往返模拟、落库顺序）——全绿；
- 全量 Desktop Replay + `note@ohosTest`/`note@default`
  clean 构建见本节提交说明。

## 影响文件

- `note/src/main/ets/data/NotePackageSpec.ets`
- `note/src/main/ets/data/NoteExporter.ets`
- `note/src/main/ets/data/NoteImporter.ets`
- `note/src/main/ets/data/OriginalRecordingOperation.ets`
- `docs/migration/replays/d03-original-import-recordings.mjs`
- `docs/migration/evidence/original-import-recordings-2026-09-28.md`
- `docs/migration/adr/ADR-0596-original-import-recordings.md`
- `docs/migration/reports/phase-627-original-import-recordings.md`
