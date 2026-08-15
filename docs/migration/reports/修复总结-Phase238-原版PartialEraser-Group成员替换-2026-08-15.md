# Phase 238 修复总结：原版 Partial Eraser Group 成员替换

## 本阶段目标

在 Phase 237 的 Ink 实体残片替换基础上，补齐原版 `wc` mode 3 的 Group member replacement、空 Group
递归删除，以及本地/持久 Undo/Redo 对称恢复。

## 原版结论

- 同一 member 有多个 parent 时，选 operation identity 最大的有效 Group。
- member list 不是原位插入残片，而是先删除 source，再把该 source 的 remnants 追加到列表末尾。
- Group 变空时不写空 `MODIFY_GROUP`：删除它，并从 parent 删除其 ID；parent 变空继续向上递归。
- 提交顺序是 `CREATE_INK → MODIFY_GROUP → DELETE_ENTITIES(sources + empty Groups)`。
- 详细 JADX 证据与文件 hash：
  `docs/migration/evidence/original-partial-erase-group-replacement-jadx-2026-08-15.md`。

## 已完成修复

1. 新增 `OriginalPartialEraseGroupPlanner.ets`：
   - 复用原版 identity parent 冲突规则；
   - 严格实现 remove-then-append；
   - 递归收集 empty Groups；
   - 可正反 replay affected Group 快照，供持久历史与本地 fallback 共用。
2. `NoteCanvasView.partialEraserCandidateStrokes()` 不再排除 Group members。
3. `StrokePersistence.commitOriginalPartialErase()`：
   - 移除 grouped-source 拒绝；
   - 在分配真实 remnant IDs 后生成 Group plan；
   - 发 type-21 MODIFY_GROUP；
   - 一个 type-25 删除 sources 与 empty Groups；
   - 校验最终 note-wide active Groups 与 planner 完全一致；
   - 返回并安装最新 `selectionGroups`。
4. 专用 partial-erase history 扩展为 NPE2：
   - 保存 page mutation、source→remnant mapping、before/after Groups；
   - validator 重新执行 planner，拒绝矛盾或越权 Group 快照；
   - 旧 NPM1 继续解码，无 Group 动作继续写 NPM1。
5. 持久 Undo/Redo：
   - 校验 active Group 与 hidden Group 的 stored member register；
   - 反向发 surviving Group 的 MODIFY_GROUP；
   - 在同一个 visibility payload 中切换 sources、remnants 与 empty Groups；
   - 每次仍只推进一个 page revision并重建 search。
6. 本地 transaction-failure fallback：
   - 同样更新 Group member/empty Group；
   - `EraseElementsAction` 保存 before/after Group snapshots；
   - 本地 Undo/Redo 同时恢复 stroke 顺序、页面 element order 与 Group 状态；
   - 独立本地 planner 接受先前 fallback 产生的 `#erase-*` member ID，连续局部擦除不会失效；持久入口仍
     保持 canonical operation ID 严格校验。
7. 预算加固：`sources + remnants + empty Groups` 不得超过 type-25 的 10,000 targets；Group members
   不得超过 10,000。
8. clean default HAP 暴露并修复了 planner 将 `OriginalSelectionGroup` 结构化传给
   `OperationIdentity` 的 ArkTS 严格类型错误；现改为显式 identity value，保持原版比较语义不变。

## Fixture 与 replay

- 新增 `OriginalPartialEraseGroupPlanner.test.ets`：
  - 最高 identity parent；
  - remove 后 append 的 member 顺序；
  - 多层 empty Group 递归删除；
  - 删除 Group 的 Undo/Redo 恢复；
  - 非 canonical draft remnant 的本地 fallback 对称 replay；
  - draft remnant 进入 Group 后再次局部擦除。
- 扩展 NPE2 codec fixture、persistent history fixture 与专项桌面 replay。
- 专项 `d02-local-partial-eraser-ink.mjs`：通过。
- 全量桌面 replay：`REPLAY_FILES=223 FAILED=0`。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 742 ms`。
- clean 后 `note@ohosTest` HAP 的 `OhosTestCompileArkTS` 与打包：
  `BUILD SUCCESSFUL in 6 s 972 ms`。
- clean 后 `note@default` HAP 的 `CompileArkTS` 与打包：
  `BUILD SUCCESSFUL in 29 s 717 ms`。

## 尚未执行/后续

- 未启动设备、模拟器、虚拟机或 Hypium。
- Shape source、Shape→Ink 与其 custom/fill outline clipping 已由 Phase 239 补齐；剩余主要是已有 Pencil/
  custom/fill Ink 的精确 clipping 与 transient protocol。
