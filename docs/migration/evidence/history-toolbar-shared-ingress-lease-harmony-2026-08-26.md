# Harmony 证据 — 撤销重做绕过共享租约的历史缺口

- 缺陷时序：
  - 照片导入持有父级 `photoImportLeaseActive` 与 Canvas `photoImportBusy`；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除共享租约或回报父页；
  - 工具栏撤销/重做回调原只检查页面操作和历史待定；
  - Canvas 统一历史入口也缺少共享租约检查；
  - 可取消裁剪会话、应用元素/页历史，或在跨页分支请求切页。
- 影响边界：撤销栈、元素数组、`elementOrder` 与当前页身份可在照片结果合并前变化；
  跨页历史还会把页面导航与照片收口并发。
- 修复事实：父页两个回调先拒绝共享导入租约；Canvas `performHistory()` 在内部历史
  门禁前拒绝同一租约。历史分组、跨页恢复和裁剪取消语义不变。
- 验证：新增 `d02-history-toolbar-shared-lease-bound.mjs` 锁定双回调守卫、统一入口
  顺序及副作用路径；当前输出 `TOTAL=10 FAILED=0`。
