# ADR-0439: 剪贴板粘贴与视口控制纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

选区菜单入口已有共享租约守卫，但 `canPasteClipboardNow()` 只拒绝历史租约。长按菜单可
在导入窗口内启动系统剪贴板图片导入；普通粘贴可预留 operation identity、执行 Group Paste
持久化并入栈历史。缩放按钮与适配宽度还会触发防抖视图状态写入。

## 决策

`canPasteClipboardNow()` 在历史租约前显式拒绝共享导入；`pasteClipboard()` 增加共享导入与
历史租约双层防御。缩放加减和适配宽度按钮在共享导入期禁用。剪贴板快照、Group Paste、
operation identity 和防抖保存语义不变。

## 结果

照片导入收口前不能发起新的普通或图片粘贴，也不能触发视口持久化续体。焦点 Replay 锁定
门禁顺序、双层防御与三个视口控件。未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal
最后任务。
