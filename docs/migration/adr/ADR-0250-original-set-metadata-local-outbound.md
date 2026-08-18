# ADR-0250：原版 SET_METADATA 六项本地出站与原子持久化

## 状态

Accepted - Phase 272（2026-08-18）

## 背景

Phase 270 已把原版 `SET_METADATA` field 2～7 解码为六个独立 winner，并完成 Harmony v65 数据表、值域和
按 `(timestamp, siteId)` 的入站 LWW。Phase 270/271 仍缺少本地编辑器或设置路径重新生成这六项的原版 FlatBuffer；
如果继续只写 Harmony 私有状态，会在快照、上传和重启后失去原版 wire 语义。

原版 `xj2.K()`/`xj2.d()` 证明：field 0/1/2 是 wrapper，field 3～7 是 nullable scalar/string/enum；boolean、
layout、wrap 即使为 `false/0` 也会保留 vtable presence。`rz1.O()` 还证明 handwriting wrapper 存在且 inner string
缺席是显式 null，而不是“没有 patch”。

## 决策

### 1. 以显式 presence patch 作为本地 API

新增 `OriginalNoteMetadataPatch`，每一项都用 `has...` 表达是否出现在原版 operation 中：

- `hasHandwritingLanguage=true, handwritingLanguage=null`：清空 handwriting register；
- `hasAlignTextToLines=true, alignTextToLines=false`：写入显式 false；
- `hasLayoutMode=true, layoutMode=PAGED(0)` 与 `hasBlockWrapSupport=true, ...=WRAP_ENABLED(0)`：写入显式 0；
- title/background field 0/1 在本地六项 writer 中永远缺席，防止偏好设置意外重置纸张或标题。

writer 在生产 reducer 前先走同一 `OriginalFlatBufferTableReader` 解码，因而 default font size 的比较使用实际
Float32 canonical value，而不是调用方未舍入的 JS number。

### 2. 复用原版 reducer，不复制第二套 LWW

`OriginalNoteMetadataPersistence` 只负责编码、事务编排、readback 和 operation-log append；winner 比较、冲突处理、
SQL 写入和 `structure_revision` 仍统一由 `OriginalSetMetadataOperationApplier` 完成。这样 local outbound 与 incoming
operation 必须经过同一值域/LWW/显式-null路径。

### 3. 事务由 repository 统一拥有

持久化 helper 不自行开启或提交事务。`NoteRepositoryImpl.updateOriginalNoteMetadata()` 在
`libraryMetadataMutationMutex` 下执行：

```text
encode/decode canonical → read before → allocate identity → reducer apply
→ readback/untouched checks → revision +1 → updated_at → operation_log append → commit
```

任何一步失败都由 repository rollback；不允许出现 winner 已写但 operation_log 缺失、revision 已增但字段未完成、或
只写入部分六项的状态。

### 4. 暂不伪造六项的 UI consumer/history

本阶段提供 concrete repository API，但不把它塞入 `NoteRepository` 公共接口，也不新增六项 Undo/Redo codec；这是为了
避免在 PAGELESS、align-to-lines、handwriting provider、default-font inheritance、block-wrap consumer 尚未逐项
取得原版调用图证据前，误把持久化入口当成完整 UI 行为。

## 后果

正面：

- 本地六项修改会产生与原版一致的 `ORIGINAL_SET_METADATA` envelope，可上传、重启和后续快照重建；
- false/0、handwriting explicit null 和 Float32 rounding 不再在本地出站时丢失；
- winner、revision、updated_at、operation_log 共享一个可回滚边界；
- 未请求的 title/background/其他 metadata register 不会被隐式重置。

代价与限制：

- 目前没有六项的 durable editor history companion，因此不能宣称 Undo/Redo 已闭环；
- 真实设置页面、页面布局、识别 provider、字体继承和换行 consumer 仍需后续原版证据与设备验收；
- 旧库升级、多设备 round-trip 与现场性能仍不由静态 Replay 覆盖。

## 验证契约

- 原版 Replay 必须锁定 `xj2/l2d/rz1` 的 field 顺序、wrapper-null 和 force-default 语义；
- ArkTS fixture 必须覆盖 concrete、explicit-null、false/0、omitted field 与非法 patch；
- persistence Replay 必须证明 canonicalization → reducer → readback → one revision → append 的顺序；
- 独立 SQLite model 必须证明 operation-log 失败时 winner/revision 全部回滚；
- `git diff --check`、`note@ohosTest` 和 `note@default` 严格串行通过；不启动任何设备、模拟器、虚拟机、真机或 Hypium。

## 未决项

- 六项 metadata 的页面/编辑器 consumer 与默认值继承；
- 六项本地 Undo/Redo、跨设备 sync 和 NOTE_BUNDLE round-trip；
- 真实旧数据库 v65/v66 升级与设备体验。
