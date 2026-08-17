# ADR-0248：原版 SET_METADATA 六项独立寄存器

## 状态

Accepted - Phase 270（2026-08-18）

## 背景

ADR-0048/Phase 70 只接收原版 `SET_METADATA.title` 与 `pageBackground`。只要 field 2～7 任一出现，旧
`OriginalSetMetadataOperationApplier` 就返回 `SET_METADATA_FIELDS_UNSUPPORTED`，因此完整 NOTE_BUNDLE 或同步流中的
handwriting language、align-to-lines、default font family/size、layout mode 和 block wrap support 会把队首长期
defer，后续操作也无法继续。

重新直读原版 1.0.3 `l2d/xj2/rz1/v69/fqb/so5/a79/u5j/tv6/dz0` 后确认：六项不是附属 JSON，也不是与
title/background 共用 winner；它们各自拥有 presence、值域和严格 greater LWW register。完整证据见
`docs/migration/evidence/original-set-metadata-registers-jadx-2026-08-18.md`。

## 决策

### 完整解码原版八字段表

- field 0/1 继续为 title/pageBackground wrapper；field 2 新增 handwriting wrapper；field 3～7 按 FlatBuffer
  vtable presence 解码 align、family、size、layout、wrap。
- handwriting wrapper 存在但内部 string 缺席表示显式 null；不能与 field 2 缺席混同。
- boolean 与 byte enum 即使值为 false/0，只要 vtable field 存在就必须视为 patch。

### 恢复原版值域并保留显式 fail-safe

- handwriting 使用首个 `_` 前的精确 Java ISO language code；固化 188 项并保留 `he/iw`、`id/in`、`yi/ji`。
- family 最多 30 个 UTF-16 code unit；layout 仅 0/1；wrap 仅 0/1/2。
- note-level template PDF 的 `pagesConsumed` 必须为 1。
- font size 在原版 `>0` 基础上额外要求有限；拒绝 NaN/Infinity 是 Harmony 数据完整性加固。
- decoder 对 handwriting/family 使用有界 UTF-8 读取，避免恶意 operation 造成无界分配。

### 六张表保存六个独立 winner

数据库升级到 v65，并新增：

- `original_note_handwriting_language_winner`；
- `original_note_align_text_to_lines_winner`；
- `original_note_default_font_family_winner`；
- `original_note_default_font_size_winner`；
- `original_note_layout_mode_winner`；
- `original_note_block_wrap_support_winner`。

每张表以 `note_id` 为主键，独立保存 `(winner_timestamp,winner_site_id)`，并通过 `ON DELETE CASCADE` 跟随
`note_meta`。handwriting value 可 null，其余字段按原版 presence/value contract 非 null。

### 每字段独立 LWW，混合 operation 仍保持原子

- 每个 present 字段分别与自己的 winner 比较 unsigned `(timestamp,siteId)`。
- strictly newer 才写；stale 字段 no-op，所以同一 operation 可更新部分字段而跳过另一些字段。
- same identity/same value 为幂等 no-op；same identity/different value 作为损坏冲突 deferred。
- 在任何 winner、materialized state 或 PDF asset write 之前，必须完成全部字段的 identity 冲突判断。
- `mergeOriginalAssetReference()` 只在 background register 实际获胜后调用；stale PDF 不能附加资产。
- 至少一个字段变化时只推进一次 `structure_revision`。

### 提供持久 readback，但不提前发明 consumer

新增 `readOriginalNoteMetadataState()`，恢复六项持久值，并保留 handwriting “寄存器缺席/显式 null”的区别；读取时若
SQL 值越界则 fail closed。blank-note bootstrap 的 fresh gate 同步检查六张表。

本阶段不把这些值强行接入未证明的 Harmony 行为：

- 不用 defaultFontSize 替换 CREATE_BLOCK 当前固定 17；
- 不宣称 PAGELESS 画布、align-to-lines、handwriting recognition、wrap 或 default-font UI 已等价；
- 不新增六项本地出站 writer，也不把 SQL readback 冒充完整 UI/设备闭环。

## 后果

- 原版 NOTE_BUNDLE/同步队首不再仅因 field 2～7 正常出现而永久 deferred。
- 六项可跨数据库重启保存，并与 title/background 一样参与按字段的确定性 LWW。
- handwriting 显式清空不再退化成“字段缺席”。
- 混合 payload 中某个字段冲突时，不会先污染其他 winner、title/background materialization 或 PDF asset 引用。
- v65 迁移只新增表，不回填猜测默认值；旧库升级后六项保持“尚无 winner”。
- 后续 consumer 可以从一个经校验的持久状态入口接线，而无需重新解释原版 wire payload。

## 验证契约

- 原版源码 Replay 必须锁定八字段顺序、scalar presence、wrapper null、八独立 register、严格 greater comparator、
  enum byte 和 snapshot serialization。
- SQLite Replay 必须执行 v65 六表 DDL、域约束与六表 foreign-key cascade。
- 独立模型必须覆盖部分字段获胜、stale no-op、site tie-break、幂等、same-identity conflict 和单 revision。
- 混合 title/background/六项冲突必须在任一写入前结束；stale PDF background 不得附加资产。
- ArkTS fixture 必须覆盖六字段 FlatBuffer、handwriting explicit null、非法 language/family/size/enum 和
  template PDF `pagesConsumed != 1`。
- clean 后 `note@ohosTest` 与 `note@default` 必须严格串行构建；不启动设备、模拟器、虚拟机、真机或 Hypium。

## 未决项

- PAGELESS 的主画布/页面管理/缩略图布局与滚动模型；
- align-to-lines 对 Text block 创建、移动和基线吸附的原版消费链；
- handwriting language 与 Harmony 识别 provider 的能力映射和无 provider fallback；
- default font family/size 的本地设置入口、CREATE_BLOCK/编辑器继承规则与出站 operation；
- blockWrapSupport 的文本换行 consumer；
- 多设备 sync、保存重启、NOTE_BUNDLE round-trip 与真实旧库升级；
- 设备像素、手感和性能验收。
