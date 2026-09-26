# ADR-0776 — MainActivity dispatch/lifecycle 语义归档

- 状态：已接受（登记型，无新移植义务之外的缺口）
- 证据：`docs/migration/evidence/phase-832-mainactivity-semantics.md`
- 回放：`docs/migration/replays/d02-mainactivity-semantics.mjs`（15/15）

## 新增登记项

1. **force-update 阻断流**：requestCode 1123 更新失败 →
   不可取消对话框（6 字符串族）。Harmony 无应用内更新
   runtime（应用市场系统机制）——**不移植，登记**。
2. **New Window 和弦门控**：`oim.a` = `smallestScreenWidthDp
   >= 600`——平板专属。和弦本体未实现（ADR-0771 缺口），
   门控规则一并登记。
3. **showWhenLockedPolicy 持久化键**：`onSaveInstanceState`
   持久化；Harmony 无锁屏可达模式（ADR-0770），登记。
4. **触摸 SecurityException 守卫**（nxb）、三路 dispatch
   埋点（fzm.b/c/d）、onUserInteraction 打点、
   onTopResumedActivityChanged 多窗回调——平台特有或埋点
   面，归档。

## 后果

MainActivity 15 个 override 全部归因完毕（826 attrs +
827 key/sensor + 本相位 body 语义）。原版入口 Activity
行为面无未解释项。
