# ADR-0399：修复临时编辑器恢复与页面切换的回归冲突

## 状态

已接受（2026-08-25，Phase 422）。

## 背景

Phase 420 在 Math 编辑取消/导航分离和图片裁剪取消路径中，于 `updateSelectionOverlay()` 后无条件执行
`selectionVisible = true`。该写法能恢复仍有效的概念选区，但页面切换顺序是先调用这些取消路径，再加载目标页并
`selectionTool.deselect()`。旧选区在取消瞬间仍然存在，因此旧浮层会在新页数据加载前后短暂复活；
如果加载失败或上下文过期，还可能残留到错误页。

## 决策

1. 恢复可见性不能绕过空态判定；必须依赖 `updateSelectionOverlay()` 的同一 selection snapshot。
2. Math 取消/导航分离移除显式 true：有效选区时 helper 已设置 true，页面切换后 deselect 时 helper 会隐藏。
3. 图片裁剪取消同样移除显式 true，保留重装原图 ID、刷新几何/能力与 nullable Ink reset。
4. 图片裁剪确认的两条成功路径保留显式 true：其入口要求 crop session 存在且当前页一致，
   提交前重新选择刚确认的图片 ID，不存在 Phase 420 发现的跨页窗口。

## 后果

有效临时编辑器转换仍会恢复浮层；页面切换、deselect 或其他权威退出后不再复活旧浮层。
可见性状态始终由最近一次 selection snapshot 推导。Replay 增加“取消路径不得强制显示”和
“页面切换先关闭临时编辑器”断言。
