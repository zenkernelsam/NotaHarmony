# ADR-0422: 跨页历史失败后先释放租约再恢复选页

日期：2026-08-26

## 状态

Accepted

## 背景

跨页 Undo/Redo 先把父页置入 `historyPending` 导航租约，再请求目标页。目标页加载
失败且源页仍存在时，`switchPageData()` 会还原源页内容并把 `loadedPageId` 指回源页。
但恢复请求 `onRequestPage(fromPageId)` 原来在 catch 末尾的
`onPageHistorySettled(false)` 之前发出；父页门控看到原历史命令仍挂起而直接拒绝，
父级选页停留在失败目标页，与 Canvas 已恢复的源页数据分叉。后续保存或操作可能命中
错误页面上下文。

## 决策

在确需请求源页时，若本地仍持有挂起历史方向，先清零方向并发布
`onPageHistorySettled(false)`，再调用 `onRequestPage(fromPageId)`。这样父页门控按
“历史命令已收口”处理恢复导航。catch 末尾保留残留方向守卫，覆盖非历史失败和已提前
释放后的重复结算幂等场景；不新增状态字段或绕行参数。

## 结果

失败恢复后父级选页、Canvas 加载页和持久化目标重新一致；正常跨页 resume、成功提交、
加载终态失败释放以及既有第二层 generation/pageId 防御不变。专项 Replay 锁定
“清方向 → settled(false) → onRequestPage”顺序，并确认末尾残留守卫仍在。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
