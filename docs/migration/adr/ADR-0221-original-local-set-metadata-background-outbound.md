# ADR-0221：本地纸张设置写原版笔记级 `SET_METADATA.pageBackground`

## 状态

Accepted，2026-08-16。

## 背景

Harmony 的纸张面板此前把尺寸、模板和方向写进当前 `PageInfo`，使用页面级 `PAGE_SETTINGS` Undo。原版 1.0.3
却由 `uge → l3a → qgh → u5j.H/xj2` 生成 payload type 1 `SET_METADATA`，更新独立的笔记
`pageBackgroundRegister`；普通 page register 保持 null 并继承该 winner。

若继续写当前页物化列，会出现三个分叉：同一笔记其他 fallback 页不更新；上传端没有原版 operation；旧
PAGE_SETTINGS Undo 可绕过 note-level LWW winner。另一个隐蔽差异是 null winner 的有效显示虽等同 Letter，
但原版 Undo 会发 `qgh.b(null)`，不能用具体 Letter `nz9` 代替。

## 决策

1. `NoteBackgroundSettings` 同时保存 effective `background` 和 exact nullable `registerBackground`。null register
   只能对应原版 Letter fallback；具体 register 必须与 effective background 完全一致。
2. `applyOriginalPaperSettings()` 按 `l3a.a()` 生成 Float32 source size：imperial ×72、A 系列 ×2.83465；保留
   PDF 与 cardinal rotation，模板 spacing 为 36 pt，四边 margin 为 36 pt，Lines bleeds=false，Grid/Dots
   bleeds=true，centered=false。
3. 设置面板方向来自未旋转 source size；渲染宽高继续包含已保留的 rotation。两者不得互相覆盖。
4. `OriginalSetMetadataPayloadEncoder` 写完整 `l2d.field1 → m2d.field0 → nz9` FlatBuffer，覆盖 paper、PDF、
   64-byte hash、UTF-8 metadata、crop vector、rotation、source size 与 margins。explicit null 时保留 `m2d`
   table，只省略其 value。
5. `persistOriginalNoteBackground()` 在共享 editor mutex 与单一 SQLite transaction 中：检查完整且对齐的原版
   page identity、分配 operation identity、包装完整 `uq9`、调用生产 `OriginalSetMetadataOperationApplier`、
   验证 winner/materialization/revision，再追加 `ORIGINAL_SET_METADATA` 上传行与 NBG history companion。
6. `UPDATE_NOTE_BACKGROUND` durable history 保存 before/after 的 effective + exact register state。Undo/Redo 每次
   都生成新的原版 `SET_METADATA`；从默认/null 状态撤销时必须再次写 explicit-null setter。
7. `ORIGINAL_SET_METADATA` 是无 history 的上传 companion，对 `PersistentHistory` 透明，不能切断本地 Undo 栈。
8. 普通本地 `CREATE_PAGE` 不复制 note background 到 page winner；payload background 保持 null，生产 reducer
   从当前 note register 物化尺寸/模板/方向，新页继续继承后续笔记设置。
9. 只要页面已有 original identity，旧 `updatePage/PAGE_SETTINGS` 路径就写前拒绝。完全没有原版 identity 的
   legacy/imported Harmony 笔记暂不伪造 SET_METADATA；其迁移/bootstrap 另行设计。

## 结果

- 一次纸张设置同时更新所有 page-register-null 的 live/archive 页，并产生可上传的原版 type-1 operation。
- PDF、rotation、crop 和资源 metadata 不会因选择纸张尺寸/模板而丢失。
- 新页继续继承笔记背景，而不是冻结为创建时的 page-level 副本。
- 持久 Undo/Redo 恢复原版 nullable register，不再只保证视觉近似。
- 任何 identity 覆盖不完整、selected page 不存在、reducer defer、revision 异常或结果不一致都会整事务回滚。

## 被拒绝的方案

- 继续修改当前 `PageInfo`：绕过原版 note CRDT，其他页与同步端都会分叉。
- 写 `MODIFY_PAGE.background`：该字段属于明确页面级 background mutation，不是纸张设置面板的原版路径。
- Undo 时总写具体 Letter：视觉相同但 nullable winner 不同，违背 `vnf` 的原版逆操作。
- 新页复制当前 note background：会把继承关系错误固化成 page winner，后续 note setting 不再作用于该页。
- 原版 identity 不完整时静默降级：会制造更难恢复的双写状态，故选择 fail closed。

## 验证与后续

- ArkTS fixture 覆盖完整 FlatBuffer、explicit-null、A 系列 Float32、source orientation、PDF/rotation 保留与 NBG
  durable history。
- `d02-local-set-metadata-background-outbound.mjs` 覆盖 exact-null Undo/Redo、fallback 页、新页继承、history
  transparency、identity coverage 和事务故障回滚。
- 原版线性证据见
  `docs/migration/evidence/original-local-set-metadata-background-outbound-jadx-2026-08-16.md`。
- 本阶段不运行设备、模拟器、虚拟机或 Hypium；多端 LWW、真实上传 ACK、重开与 PDF 像素表现留待集中真机验收。
