# ADR-0215：Partial erase 必须同步替换 Group member 并递归删除空 Group

## 状态

Accepted，2026-08-15。扩展 ADR-0214。

## 问题

ADR-0214 已把普通 Ink partial erase 改为 `CREATE_INK remnants + DELETE_ENTITIES sources`，但当 source
属于 Group 时，旧实现会主动跳过它；持久层也拒绝 grouped source。若只解除这两个门禁而不维护 Group，
则会留下指向 tombstone source 的 member、丢失残片的组合关系，并在 Group 变空时产生不可选的幽灵 Group。

## 原版证据

`wc` mode 3 的精确语义见
`docs/migration/evidence/original-partial-erase-group-replacement-jadx-2026-08-15.md`：

1. 多个 Group 同时声明同一 member 时，选择 operation identity 最大的有效 parent；
2. 对每个 source 先 `removeAll(source)`，再把该 source 的 remnant IDs `addAll` 到 member list 末尾；
3. 受影响 Group 变空时不发空 members 的 `MODIFY_GROUP`，而是删除该 Group，并从有效 parent 删除它；
4. parent 也变空时继续向上递归；
5. 最终顺序为 `CREATE_INK → MODIFY_GROUP(non-empty) → DELETE_ENTITIES(sources + empty Groups)`。

## 决策

1. 新增纯函数 `OriginalPartialEraseGroupPlanner`，以 active Groups 与有序 `source → remnantIds[]` 为输入：
   - parent 冲突复用 `compareOperationIdentity` 的最大 identity 规则；
   - member 顺序严格采用 remove 后 append；
   - 递归输出 empty Groups；
   - 输出 before/after affected Group 快照、待发 MODIFY_GROUP 列表及最终 active Groups。
2. Canvas partial eraser 不再排除 Group members。canonical original 提交仍需通过既有 source、页面、身份与
   reservation 门禁。
3. 持久提交在同一数据库事务内按原版顺序：
   - 创建并取得真实 remnant operation IDs；
   - 对所有仍非空的 affected Groups 发 type-21 `MODIFY_GROUP`；
   - 用一个 type-25 删除 sources 与递归产生的 empty Groups；
   - 页面 revision 仍只由这次 visibility operation 推进一次；随后同事务重建 snapshot/search/history。
4. 专用 history 增加 NPE2 格式：保存 page mutation、有序 replacement mapping、before Groups 与 after
   Groups。decoder 继续接受 Phase 237 的旧 NPM1；无 Group 的新动作仍编码为 NPM1。
5. NPE2 validator 必须用 replacement mapping 重新执行纯 planner，并要求结果与 before/after Group
   快照完全一致，避免历史 payload 借 partial erase 任意修改或删除无关 Group。
6. Undo/Redo 对仍存活的 affected Groups 反向发 `MODIFY_GROUP`；对 empty Groups 只切换 visibility，
   因为原版提交从未把其 stored members 写成空数组。source/remnant/empty-Group visibility 仍合并为一个
   type-25，因此每次历史移动只推进一个 page revision。
7. 单个历史 visibility payload 的预算改为
   `sources + remnants + recursivelyDeletedGroups <= 10,000`。Group member 数仍受原版 10,000 上限约束。
8. original transaction 失败后的本地实体替换也应用同一 planner，并把 before/after Group 快照存入
   `EraseElementsAction`，使当前会话的本地 Undo/Redo 对称恢复 Group。本地入口允许先前 fallback 产生的
   `#erase-*` member ID，因此同一 Group 残片可以继续被局部擦除；持久/NPE2 入口仍严格要求 canonical ID。

## 结果

- Group 内普通 Ink 可以像原版一样被 partial erase，不再被静默排除。
- 残片仍保持 source 的页面 z-index；Group member list 则保持原版 remove-then-append 顺序，两套顺序各司
  其职。
- 空 Group 与连续空 parent 不再残留，Undo/Redo 可恢复原成员和 visibility。
- restart 后的专用持久历史仍是单一动作边界，且旧 NPM1 动作继续可读。

## 边界

- 本 ADR 只覆盖 ADR-0214 已支持的普通 Ink 中心线裁剪；Shape、Pencil、custom/fill outline clipping 仍需
  后续阶段。
- transient preview/end 的完整原版协议仍未闭环。
- transaction failure 的非 original fallback 会保留当前会话 Group 对称历史，但不会伪造 original
  MODIFY_GROUP 协作 operation。
- 本阶段不启动设备、模拟器、虚拟机或 Hypium；真机仍需覆盖嵌套 Group、多父冲突和录音 Ink 场景。
