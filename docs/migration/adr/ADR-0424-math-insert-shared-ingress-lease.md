# ADR-0424: 数学插入纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

照片导入持有父页 `photoImportLeaseActive` 与 Canvas `photoImportBusy`。异步持久化
提交后先释放 `historyBusy`，再进入外层 `finally` 收口共享导入租约并回报父页。
工具栏数学插入此前直接递增 `mathInsertSignal`，Canvas 的 `startMathInsert()` 也只
检查生命周期、编辑器可见性、历史、健康与页身份，未等待共享导入收口。

## 决策

`onInsertMath()` 在递增信号前拒绝父级照片导入、页面操作、历史待定与页面结构租约；
`startMathInsert()` 在内部历史门禁前拒绝 Canvas `photoImportBusy`。双层闸门保持既有
状态字段和数学编辑器逻辑不变，只让工具栏入口与选区菜单一样等待导入收口。

## 结果

数学编辑器不再于照片导入收口前打开；确认数学插入也不会与其收口竞争元素顺序或撤销栈。
新增焦点 Replay 锁定两侧守卫及检查顺序。未启动模拟器、虚拟机、真机或 Hypium；
T-042 保持 Goal 最后任务。
