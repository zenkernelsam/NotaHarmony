# Phase 130 修复总结：原版 Group 剪贴板复合 Paste 协议

## 原版证据与边修边审

- 原版 `lg2.g()` 递归收集选中 Group 后代，`u5j.c()` 通过模型复制路径为叶实体和 Group
  生成新操作；Group Paste 不是扁平复制后在 UI 内存中补一个分组。
- 原版 `lg2.e()` 从实际生成的 `CREATE_GROUP` 操作中排除 nested child Group，以剩余根 Group
  恢复选择。因此“Group 创建顺序”和“顶层根集合”都属于 Paste 的持久语义。
- 现有 `NGM1` 明确限制一个 Group 且禁止页面 membership 改变。直接放宽会让普通
  Group/Ungroup 接受本应拒绝的复合状态，因此新增独立协议。

## 已完成修复

- 新增 `OriginalClipboardPasteMutationCodec.ets`，以 `NCP1` 封装生产 `PageMutationOpPayload`、
  bottom-up Group 列表和顶层 Group IDs。
- 强制页面 mutation 为纯 INSERT，所有新叶实体为 canonical operation identity；Group identity
  必须与 timestamp/site 一致且不得撞页面实体。
- Group 成员只可引用本次新增实体或更早 Group；拒绝重复成员、前向引用、多父 Group、循环、
  错误/遗漏顶层根以及尾随或截断字节。
- 允许顶层 Group 与独立未分组实体同批 Paste，并对整个复合 payload 同时执行元素数和字节预算。
- 保持 `OriginalGroupMutationOpCodec` 原约束不变，未削弱普通 Group/Ungroup。
- 新增 ArkTS fixture 并注册到 `List.test.ets`；新增桌面 replay 与 ADR-0107。

## 验证

- 专项 replay 输出：
  `originalGroupClipboardPasteProtocol=insert-only-canonical-bottom-up-tree-exact-roots-independent-leaves-budgeted`。
- 全量桌面 replay 为 `TOTAL=116 FAILED=0`，覆盖原版证据、协议静态门禁、nested Group、独立叶实体、
  前向引用、多父和根集合；`git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、虚拟机、真机，也未执行 Hypium。

## 后续

- 下一阶段接入 persistent history materializer 和 `StrokePersistence` 单事务生产路径。
- 随后用一个 type-25 payload 同时切换本次叶实体与 Group 的可见性，完成复合 Undo/Redo；最后让
  `StrokeClipboard` 保存完整源 Group 图，并在持久提交成功后更新 UI 元素、层序、Group 与顶层选择。
