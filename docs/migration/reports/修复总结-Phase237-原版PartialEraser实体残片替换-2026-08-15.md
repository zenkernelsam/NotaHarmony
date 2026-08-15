# Phase 237 修复总结：原版 Partial Eraser 实体残片替换

## 发现

Phase 108 把原版 partial eraser 的 tool-5 输入语义误当成最终持久表示，导致本地手势永久追加
`destination-out` Ink。重新跟踪 `dh5 → jt1 → n8j/o8j → wc mode 3` 后确认，原版对普通 Ink 的最终结果是：

- 每个命中 source 被裁为零至多个新 Ink；
- 新残片分别 CREATE_INK；
- source 统一 DELETE_ENTITIES；
- AudioLinked 残片按各自路径区间重算时间；
- 原版后续还维护 Group 并结束 transient interaction。

普通 JADX 缺失 `jt1.invokeSuspend()` 与 `wc.invoke()`，已用 JADX 1.5.6 fallback 线性反编译补齐，APK、命令、
两个 fallback 文件 SHA-256 和摘录已固化到 evidence 文档。

## 修复

- `EraserEngine` 的 partial 模式改为返回 `PartialEraseReplacement[]`，本地不再生成永久 tool-5 mask。
- 当前安全范围内的普通 Ink 使用中心线采样与几何区间切分；Pencil、tape、custom/fill outline 暂不进入该近似
  路径，避免为追求表面“可擦”而破坏原生纹理/轮廓。
- 每个 remnant：
  - 获得独立临时身份，canonical transaction 中再分配真实 original operation identity；
  - 保留 source transform、颜色、宽度、Ink style/effects；
  - `inkEffectPhase` 加上残片起始路径距离；
  - 按路径比例重算 `audioStartTime` 与 uint32 `audioDuration`。
- CREATE_INK encoder 补写 field 15 `audioDuration`，extended table 大小扩至 `table + 76`，并拒绝非 uint32。
- `StrokePersistence.commitOriginalPartialErase()` 在一个事务内：
  - 以 source z-index 创建全部 remnant；
  - CREATE_INK 使用同一个未 flush revision batch；
  - 一次 DELETE_ENTITIES 删除全部 source 并承担唯一 revision CAS；
  - 校验 materialized entity 数量和身份；
  - 同事务 reconcile snapshot、重建 search、追加专用历史后 commit。
- 新增 `OpType.ORIGINAL_PARTIAL_ERASE = 33`、`UndoableActionType.ORIGINAL_PARTIAL_ERASE = 20` 与
  `OriginalPartialEraseMutationCodec`。持久 Undo/Redo 各只发一次 visibility operation并推进一次 revision。
- UI 增加 canonical source 校验、page generation/reservation epoch 门禁和 transaction failure fallback；失败
  fallback 仍执行实体替换，不再退回永久 mask。
- 本地 fallback 历史新增 remnant indices/counts，Undo/Redo 会验证 source/remnant 的精确数组位置、插入边界与
  元素顺序；Redo 不再把 remnant 追加到 strokes 尾部。
- 加固边修边审发现的两个损坏边界：
  - 后出现的 source ID 不得与先前 remnant ID 冲突；本地 remnant 也不得撞现存 stroke；
  - 专用 history mutation 的 before+after 总数限制为 type-25 的 10,000 实体，而不是通用 100,000 元素上限。
- 保留历史/外来 tool-5 Ink 的 reader/renderer 兼容，不再把兼容读取能力误写成本地 writer 契约。

## 历史与文档更正

- ADR-0085 已标为 Superseded，并明确废止永久 tool-5 writer。
- Phase 108 总结已增加 2026-08-15 更正，区分仍有效的兼容 reader 与错误的本地持久结论。
- 新增 ADR-0214。
- 新增原版证据：
  `docs/migration/evidence/original-partial-erase-entity-replacement-jadx-2026-08-15.md`。

## 测试与 replay

- `EraserEngine.test.ets` 覆盖 source→remnants、effects/path phase、transform 与 AudioLinked 区间。
- `OriginalCreateInkPayloadEncoder.test.ets` 覆盖 transform/z-index、uint32 audioDuration、专用 mutation round-trip
  与 10,000 实体上限。
- `PersistentHistory.test.ets` 覆盖专用历史跨 PUSH/UNDO 的单动作恢复。
- `UndoRedoManager.test.ets` 覆盖本地 fallback 的 source/remnant indices、counts、Undo/Redo 状态与元素顺序。
- `StrokePersistence.test.ets` 覆盖跨 replacement 的 source/remnant ID 冲突拒绝。
- 专项 replay 同时锁定原版证据、SQLite commit/undo/redo revision、search、历史与四个 rollback 注入点。

## 验证

- partial-eraser 专项 replay：通过，输出
  `localPartialEraser=original-evidence-entity-remnants-source-delete-transform-zindex-audio-single-revision-search-history-rollback`。
- 全量桌面 replay：`REPLAY_FILES=223 FAILED=0`。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 492 ms`。
- clean 后 `note@ohosTest assembleHap`：`OhosTestCompileArkTS` 实际执行并通过，
  `BUILD SUCCESSFUL in 7 s 494 ms`。
- 同一次 clean 后 `note@default assembleHap`：Native Ninja、`CompileArkTS` 与 PackageHap 通过，
  `BUILD SUCCESSFUL in 30 s 995 ms`。
- `git diff --check` 通过；仅有项目既有 LF→CRLF 提示和既有 ArkTS warning。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 尚未完成的原版边界

- Group member replacement 与空 Group 递归删除（已由 Phase 238 补齐）。
- Shape partial erase。
- Pencil/custom/fill outline 的原版精确 clipping。
- transient preview/end 完整协议。

## 真机待测

- 普通固定宽/可变宽 Ink：头尾、中段、多次交叉、极短残片、整条擦除和快速连续手势。
- 带旋转/缩放 transform 的 Ink，确认视觉位置、宽度、bounds 与 z-order 不漂移。
- AudioLinked Ink：比较 source 时间线与多个 remnant 的开始/持续区间，确认播放高亮无重叠或整段重复。
- Undo/Redo 多轮与重启恢复，确认每一步只变化一次 revision，search 与页面实体同步。
- transaction 失败后的本地 fallback，确认 remnant 留在 source 原位置且后续 Undo/Redo 对称。
- 含 Shape、Pencil/custom outline 的页面目前应保持未破坏，并作为后续实现验收样本；Group 场景转由
  Phase 238 的 nested/multi-parent fixture 与后续真机测试覆盖。
