# ADR-0429: 数学确认纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

Phase 452 关闭了新建数学插入入口，但导入前已打开的编辑/插入会话仍可在照片导入释放内部
历史租约后、共享租约收口前提交。`startMathEditing()`、`confirmMathEditing()` 和
`confirmMathInsert()` 原只检查 `historyBusy`，可替换或新增 Math、维护 elementOrder、推入
撤销栈并持久化。

## 决策

三个数学入口在内部历史门禁前拒绝 Canvas `photoImportBusy`。既有编辑会话保留，等待导入
收口后重新确认；CRDT 预览、页上下文和失败恢复不变。

## 结果

数学编辑与插入不再与照片导入收口竞争文档状态；焦点 Replay 锁定三入口守卫及顺序。未启动
模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
