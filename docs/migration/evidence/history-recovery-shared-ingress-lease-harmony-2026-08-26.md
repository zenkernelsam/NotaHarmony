# Harmony 证据 — 历史重置绕过共享租约的恢复缺口

- 缺陷时序：
  - 页面载入发现持久历史不可验证并弹出恢复对话框；
  - 照片导入随后持有 Canvas 共享 `photoImportBusy`；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除共享租约或回报父页；
  - 用户确认“重置 Undo 历史”可通过原入口进入；
  - 重置会置位双重忙碌、清空内存栈并执行 SQLite 持久重置事务。
- 影响边界：撤销栈和持久 history checkpoint 可在照片结果合并前变化；重置成功后
  新照片 action 的历史上下文被破坏，失败也会与收口并发占用恢复状态。
- 修复事实：request 与 reset 双入口先拒绝 `photoImportBusy` 再检查内部
  `historyBusy`。对话框路径、失败保留、生命周期守卫和 finally 清理不变。
- 验证：新增 `d02-history-recovery-shared-lease-bound.mjs` 锁定双入口顺序及 Hypium
  fixture；当前输出 `TOTAL=8 FAILED=0`。
