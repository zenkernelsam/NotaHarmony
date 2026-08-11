# Phase 134 修复总结：原版 Group Paste 复合 Undo/Redo

## 问题与边修边审

- Group Paste 的叶实体和 nested/top Groups 是一个用户动作。拆成元素与 Group 多次撤销会短暂或永久
  留下半可见图；原版已有 `DELETE_ENTITIES` type 25 向量，应该一次切换全部 identity。
- 初稿复核时发现一个协议误读：NPM1 的 `beforeElements/afterElements` 只是变更实体，不是完整页面。
  若直接拿它们与当前页比较，目标页原本有旧内容时会错误拒绝。现改为标准 `replayPageMutation()`。
- 另发现 Phase 133 原门禁只分别限制叶和 Group 数量，二者相加可能超过一条 type-25 上限，形成可
  Paste 但不可 Undo 的动作。

## 已完成修复

- 新增 `applyOriginalClipboardPasteHistory()` 单事务：验证源页面和全部 Stored Group，收集所有新叶与
  Group identity，用一条 type-25 全删或全恢复，并验证目标页面、Group 状态和单次 revision 增长。
- Undo/Redo 成功后写原 NCP1 的专用 history companion；任一 reducer deferred、源状态 stale、目标
  偏差、revision 或 history 写入失败均整体 rollback。
- Paste preflight 收紧为叶加 Group 总数不得超过 type-25 vector budget。
- Phase 133 生产结果现在返回实际持久化的 NCP1 companion `Op`，供运行时 Undo 栈与重启恢复共用。
- `NoteCanvasView` 增加专用非合并 handler：先校验 page replay 与 Group active 状态，durable apply
  成功后才移动 history 栈并安装元素、层序和 Groups。
- 新增 ADR-0111 与 `d02-original-group-paste-undo-redo.mjs`。

## 验证与后续

- 专项 `d02-original-group-paste-undo-redo.mjs` 通过；全量桌面 replay 为
  `TOTAL=120 FAILED=0`，`git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`；只有项目既有 warning。
- 未启动模拟器、虚拟机、真机或 Hypium。
- 下一阶段让 `StrokeClipboard` 保存完整源 Group 图，并让 Paste UI 调用 Phase 133 事务，仅在成功后
  更新画布、顶层 Group 选择和专用 Undo action。
