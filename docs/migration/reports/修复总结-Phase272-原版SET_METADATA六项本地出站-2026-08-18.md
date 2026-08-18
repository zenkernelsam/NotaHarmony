# 修复总结：Phase 272 原版 SET_METADATA 六项本地出站与原子持久化

## 1. 基线与纪律

- 唯一可写工程：`C:\HarmonyProject\NotaHarmony`。
- `C:\Users\Cisco He\Desktop\Notability` 仅用于读取原版 APK/decompiled/JADX 证据；本阶段没有在 Desktop
  新建或维护 Harmony 源码工作树。
- 阶段开始时 `HEAD=6f5201105e4fc994e2deeac6d4e3cb6c8833e488`，工作区只有本阶段 encoder 未提交修改及既有
  未跟踪缓存；未 push。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 2. 原版缺口与结论

直接核对原版 `xj2.java/l2d.java/rz1.java/u5j.java/a79.java` 后确认：

1. field 2 是 handwriting wrapper，可表达 wrapper present + inner string absent 的 explicit null；
2. field 3～7 分别为 align、default family、default size(Float32)、layout byte、wrap byte；
3. boolean/layout/wrap 的 `false/0` 仍有 vtable presence，不能按读值等于默认值来省略；
4. field 0/1 与六项独立，本地改偏好时必须保持 title/background 缺席；
5. `u5j` 快照链重新调用 `xj2.d(...)`，因此本地持久化必须留下原版 `ORIGINAL_SET_METADATA` envelope。

完整行号、hash 和调用图见：
`docs/migration/evidence/original-set-metadata-local-outbound-jadx-2026-08-18.md`。

## 3. 实现内容

### 3.1 原版 wire writer

`OriginalSetMetadataPayloadEncoder.ets` 新增 `OriginalNoteMetadataPatch`、
`encodeOriginalSetMetadataFields()` 与 `validateOriginalNoteMetadataPatch()`：

- root vtable 固定 field 0/1 absent；
- handwriting concrete/null 两种 nested wrapper 均可编码；
- scalar false/0 只要 `has...` 为真就写入；
- family/handwriting 做 UTF-8 round-trip 与 byte budget；
- font size 保留有限正数 policy，写入 little-endian Float32。

### 3.2 原子 local persistence

新增 `OriginalNoteMetadataPersistence.ets`：

- 先编码并通过生产 decoder 得到 canonical payload；
- 读取 coherent before state，拒绝 canonical no-op；
- 调用既有 `OriginalSetMetadataOperationApplier`，不复制 LWW 逻辑；
- readback 验证 requested field、未请求字段、显式 null presence；
- `structure_revision` 恰好 +1，更新 `note_meta.updated_at`；
- 同一事务 append `OpType.ORIGINAL_SET_METADATA`，`uploadImmediately=true`。

`NoteRepositoryImpl.updateOriginalNoteMetadata()` 在 `libraryMetadataMutationMutex` 下拥有 transaction；失败统一
rollback。当前 concrete API 暂不加入 `NoteRepository` interface，以免暗示 UI/History consumer 已完成。

## 4. Fixture、证据与 Replay

- ArkTS：`note/src/test/OriginalSetMetadataPayloadEncoder.test.ets`
  - concrete 六字段；
  - handwriting explicit null；
  - align/layout/wrap false/0 presence；
  - title/background 与 omitted field 不出现；
  - invalid language/family/size/enum reject。
- Replay：`docs/migration/replays/d02-original-set-metadata-local-outbound.mjs`
  - 原版源码门；
  - 独立 FlatBuffer concrete/null/false-zero 模型；
  - production source ordering/transaction ownership；
  - SQLite commit/rollback/no-op 模型。
- ADR：`docs/migration/adr/ADR-0250-original-set-metadata-local-outbound.md`。
- Evidence：`docs/migration/evidence/original-set-metadata-local-outbound-jadx-2026-08-18.md`。

## 5. 验证结果

| 门禁 | 结果 |
|---|---|
| Phase 272 专项 Replay | `D02_ORIGINAL_SET_METADATA_LOCAL_OUTBOUND_OK TOTAL=20 FAILED=0` |
| `git diff --check` | 通过（仅 Windows 换行转换提示） |
| 增量 `note@ohosTest` | `BUILD SUCCESSFUL` |
| 增量 `note@default` | `BUILD SUCCESSFUL` |
| 全量 Desktop Replay | `REPLAY_FILES=257 PASSED=257 FAILED=0` |
| clean | `BUILD SUCCESSFUL in 704 ms` |
| clean 后 `note@ohosTest` | `BUILD SUCCESSFUL in 12 s 885 ms` |
| clean 后 `note@default` | `BUILD SUCCESSFUL in 48 s 667 ms` |

构建输出只保留项目既有 ArkTS exception/deprecation 与 unsigned-signing warning；没有启动设备或 Hypium。

## 6. 阶段边界与后续

本阶段只闭环“六项 local outbound + wire + reducer persistence + atomic operation-log append”。不能宣称：

- PAGELESS、align-to-lines、handwriting provider、default-font inheritance、block-wrap consumer；
- 六项 metadata 的 Undo/Redo history；
- 真实旧库迁移、多设备同步、NOTE_BUNDLE round-trip、设备像素/性能。

这些缺口继续保留在总纲中，下一阶段按原版调用图选择有证据的 consumer 或 round-trip 缺口。T-042 APK 版本追踪仍留到整个 Goal 最后一项。
