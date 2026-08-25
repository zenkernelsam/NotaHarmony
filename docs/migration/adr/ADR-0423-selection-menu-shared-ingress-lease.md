# ADR-0423: 选区菜单纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

Phase 447 让 Picker 与剪贴板图片导入通过父页 `photoImportLeaseActive` 阻塞页面结构、
导航和历史切页；Canvas 内部以 `photoImportBusy` 表示同一活动。但选区菜单统一入口
只检查 `historyBusy`、加载健康与页身份。照片导入的异步持久化释放 `historyBusy` 后，
CUT/GROUP/UNGROUP 等同步元素变更可在导入收口前进入，绕过共享租约并改变
`elementOrder` 或撤销栈。

## 决策

`onSelectionMenuAction()` 在内部历史门禁前先拒绝 `photoImportBusy`。选区复制等无
持久化副作用命令与变更类命令一起等待导入收口，保持单一菜单入口串行化；照片导入、
页结构操作和既有历史防御不变。

## 结果

照片导入期间不再出现选区菜单旁路；导入完成后恢复原交互。专项 Replay 锁定入口守卫
顺序。未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
