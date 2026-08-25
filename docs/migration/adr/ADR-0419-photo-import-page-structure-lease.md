# ADR-0419: 照片导入与页面结构互斥租约

日期：2026-08-26

## 状态

Accepted

## 背景

工具栏的 `onInsertPhotos()` 只递增 `photoInsertSignal`，真正的长时入口在
`NoteCanvasView.startOriginalPhotoInsert()`：Picker 授权、URI 复制和字节解析
期间会保持 `photoImportBusy=true`。该状态是 Canvas 私有状态，父级
`NotePage.runPageOperation()` 只检查 `pageOperationBusy`、`historyPending` 和
页面结构租约，因此新增、删除、移动或背景操作可以在导入未结束时启动。

反向窗口同样存在：页操作先获得互斥后，迟到的照片信号仍可能进入 Canvas。
虽然持久化结果带 generation/pageId 防御，但这会把冲突留给失败路径，并造成
用户可感知的部分成功或陈旧上下文提交。

## 决策

1. 由父页持有跨组件 `photoImportLeaseActive`；工具栏只在页操作、历史挂起、
   页面结构租约和旧照片导入均空闲时发信号，并在发出前立即占用租约。
2. Canvas 的 Picker 导入和剪贴板图片 ingress 在 `finally` 中统一回报
   `onPhotoIngressFinished()`，保证正常、取消、异常路径都会释放父级租约。
3. `runPageOperation()` 与跨页历史请求把共享照片导入租约纳入第一道门禁；
   页结构变更必须
   等待长时 ingress 完全收口。
4. 保留既有 generation/pageId、history metadata、partial-failure 和 stale
   commit 防御作为第二层兜底，不改变持久化协议。

## 结果

照片导入与页面结构操作形成显式双向互斥：迟到信号不会进入已加锁的页操作，
页操作也不能在导入中改变当前页集合。释放点位于 ingress `finally`，避免
异常导致永久锁死；专项 Replay 与 ArkTS fixture 锁定门禁顺序和释放契约。
