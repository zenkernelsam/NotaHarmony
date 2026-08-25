# ADR-0400：图片裁剪期间阻断当前页 flush

## 状态

已接受（2026-08-25，Phase 423）。

## 背景

`flushCurrentPage()` 是页面删除、离开编辑器和历史检查点等流程的统一持久化闸口。Math 编辑已在该闸口
fail closed，防止临时编辑态在异步页操作中提交或删除当前页。但图片裁剪同样是绑定当前选中图片和当前页的
模态临时状态，此前只由入口与正常取消/确认出口防护；若用户在裁剪浮层存在时触发删除当前页，删除流程会
先 `await historyBridge.flushCurrentPage()`，随后继续快照、prepare removal 和持久化删除。

## 决策

1. `flushCurrentPage()` 在 `mathEditorVisible || imageCropVisible` 时立即返回 false。
2. 阻断必须发生在文本提交、queue save、persistence flush 和 checkpoint 维护之前。
3. 不改变裁剪确认/取消的持久化路径；确认成功后 `imageCropVisible=false`，后续 flush 语义不变。
4. 页面切换仍先关闭裁剪并加载目标页数据，本决策不新增跨页状态。

## 后果

图片裁剪与 Math 编辑获得对称的 fail-closed 行为：异步页删除在裁剪态不会推进到快照或删除持久化。
用户需先完成或取消裁剪。专项 Replay 现在断言临时编辑门禁位于所有 flush 副作用之前。
