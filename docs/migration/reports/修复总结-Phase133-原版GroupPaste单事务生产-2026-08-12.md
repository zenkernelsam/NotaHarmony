# Phase 133 修复总结：原版 Group Paste 单事务生产

## 原版证据与问题

- 原版 `lg2.g()/u5j.c()` 通过模型路径复制递归叶实体，`lg2.e()` 从实际 CREATE_GROUP operations
  恢复顶层 Group 选择。完整 Paste 不是多次独立 save，也不是先改 UI 再补历史。
- Phase 132 前后的 reducer 原语已经能共享 revision，但尚缺一个 transaction 同时承担 identity、
  叶 CREATE、Group 图、最终快照和 NCP1 history，任何中途失败仍可能留下部分状态。

## 已完成修复

- 新增 `OriginalClipboardPastePlan`、严格同步 preflight 和
  `StrokePersistence.commitOriginalClipboardPaste()`。plan/history 在首次 await 前深拷贝并二次验证，
  防止 UI 可变对象造成 TOCTOU。
- transaction 内按叶层序分配全新 identity；Ink/Shape/Text 分别产生原版 type 17、18、22，Text
  随后产生 type 8 INSERT_STRING。四类 reducer 共用一个 revision batch，同页只增长一次 revision。
- 所有叶成功后按源图 bottom-up 产生 type 20 CREATE_GROUP；每条原版 operation 都进入
  upload-immediate journal。最后按实际 Group-layered 顺序重读并校验页面，写一条 type 32 NCP1
  history companion。
- 提交前验证旧元素 payload 完全未变、所有新叶与 Groups 精确出现、NCP1 为纯 INSERT；任何 deferred、
  revision CAS、图/顺序/快照偏差或 history 故障都会整体 rollback。
- Image/Math、Styled/空 Text、Shape RichText 和不可由生产 encoder 表示的几何在零写入阶段明确拒绝。
- ArkTS fixture 覆盖合法 nested Group 图、前向 Group 引用及 Image 门禁；新增 ADR-0110 和
  `d02-original-group-paste-transaction.mjs`。

## 验证与后续

- 专项输出为
  `originalGroupPasteTransaction=stable-plan-in-transaction-identities-mixed-leaf-create-single-revision-bottom-up-groups-ncp1-rollback`；
  全量桌面 replay 为 `TOTAL=119 FAILED=0`，`git diff --check` 通过。执行 `hvigorw clean` 后严格串行
  构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`，只有项目既有
  deprecated/exception-handling warning。
- 未启动模拟器、虚拟机、真机或 Hypium。
- 下一阶段实现一个 type-25 payload 同时切换本次全部叶实体与 Groups 的复合 Undo/Redo；随后再让
  `StrokeClipboard` 保存完整源 Group 图并接入 UI 成功后更新。
