# Harmony 证据 — 损坏历史恢复中文资源缺口

- 功能来源：提交 `07cec36 fix(D-02): 恢复损坏的本地撤销历史` 只修改了
  `note/src/main/resources/base/element/string.json`，未创建
  `note/src/main/resources/zh_CN/element/string.json` 条目。
- 当前事实：
  - base 存在 `history_recovery_title/message`、`continue_editing/reset_undo_history`
    以及 needed/complete/failed toast 共七项；
  - zh_CN 在 Phase 443 前后已有照片、剪贴板权限等中文资源，但上述七项全部缺失；
  - `NoteCanvasView.promptPersistentHistoryRecovery()` 通过
    `$r('app.string.history_recovery_title')` 等引用资源，toast 同样引用
    needed/complete/failed。
- 缺陷影响：系统 locale 为中文且持久化历史重放耗尽时，原生对话框与 toast 回退英文；
  用户无法按项目既有中文界面理解“继续编辑”与“重置撤销历史”的差异。
- 修复事实：zh_CN 补齐七项，逐句映射默认英文；不改变 D-02 恢复状态机、reset 入口
  门禁、durable reset 或按钮回调顺序。
- 验证：新增 `d02-history-recovery-zh-cn-localization.mjs` 输出
  `TOTAL=9 FAILED=0`；两份资源 JSON 可解析，键值一一匹配。
