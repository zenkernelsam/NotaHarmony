# ADR-0452: 画布插入信号回调纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

工具栏入口已在父页拒绝共享导入租约，但 `NoteCanvasView` 的插入信号 `@Watch` 回调直接调用
`startMathInsert()` 与 `startOriginalPhotoInsert()`。二者内部虽有防御，但缺少回调级第一层
防线，与既有画布信号处理模式不一致。

## 决策

`onMathInsertSignalChange` 与 `onPhotoInsertSignalChange` 先拒绝 `photoImportBusy`，再进入
原有函数。Math 插入内部的共享导入、历史、加载与页身份防御，以及照片导入的
`canStartOriginalPhotoInsert()` 防御均保持不变。

## 结果

即使信号在租约开始前入队，也不会在收口窗口内重新启动插入流程；正常交互仍由双层防线保护。
焦点 Replay 锁定两处回调守卫及内部防线。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
