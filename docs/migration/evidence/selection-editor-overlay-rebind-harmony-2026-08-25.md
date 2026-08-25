# Harmony 证据：临时编辑器后选区浮层重绑

日期：2026-08-25
范围：`note/src/main/ets/ui/editor/NoteCanvasView.ets`

## 缺陷证据

- `startMathEditing()` 与 `startImageCrop()` 在保留 SelectionTool IDs 的同时设置
  `selectionVisible = false`。
- `detachMathEditorForNavigation()`、`cancelMathEditing()` 和 Math 确认投影只调用
  `updateSelectionOverlay()`；该方法会重建 `selectionRect` 并发布能力寄存器，但旧代码不再把
  `selectionVisible` 改回 true。
- `cancelImageCrop()` 会重新选择原图 ID，`confirmImageCrop()` 会重新选择裁剪后图片 ID；
  两者同样只刷新几何缓存，没有恢复可见性。
- 触摸拖拽要求 `selectionVisible && pointInRect(...)`，菜单命中也依赖该状态。
- `onViewportChanged()` 与根容器 `onAreaChange()` 只在 `selectionVisible === true` 时调用
  `updateSelectionOverlay()`。隐藏状态下即使视口改变也无法自愈。
- `selectionPasteTarget()` 在不可见时回落到 long-press anchor，导致恢复后的概念选区无法提供正确中心锚点。

## 原版参考证据

- 原版 1.0.3 `xsc.java` 持有可观察状态机：构造时初始化为 `psc.a`（空闲）。
- `t()` 设置 `ksc.a`，`u()` 设置 `osc.a`；`dhb.java` 中对应调用分别伴随
  `"Math conversion selection spans pages"` 与 `"Text conversion selection spans pages"` 日志，
  说明这些是转换型临时状态而非选区销毁。
- `m()` 显式回到 `psc.a` 并先执行 `K.e(false)`、`P.b()`；`l()` 启动异步任务后在成功分支回到 `psc.a`，
  失败分支执行调用方回调。该模型证明转换结束后必须离开专用状态并回到统一选区生命周期。
- 本次未声明 Android 的具体浮层像素行为；修复依据是 Harmony 内部状态一致性以及原版“临时状态结束不丢弃选区”的
  控制流证据。

## 修复证据

新增六个显式 rebind 点：

| 路径 | 行为 |
| --- | --- |
| Math 导航分离 | 先刷新几何/能力，再恢复可见 |
| Math 取消 | 先刷新几何/能力，再恢复可见 |
| Math 确认且页上下文有效 | 投影新 bounds 后恢复可见 |
| 图片裁剪取消 | 重装原图 ID、刷新后恢复可见 |
| 图片裁剪确认且字节相同 | 刷新后恢复可见 |
| 图片裁剪普通确认 | 提交历史、刷新后恢复可见 |

`updateSelectionOverlay()` 空态仍只隐藏；权威退出的 `selectionVisible = false` 不被本阶段改写。

## 验证证据

- 聚焦 Replay：`node docs/migration/replays/d02-selection-style-toolbar-context-bound.mjs` 通过，
  输出 `selectionStyleToolbarContext=original-inverse-map-pencil-gate-first-eligible-sync`。
- 新增断言覆盖两个入口隐藏、三个 Math 恢复点、两个裁剪恢复函数、非空模拟恢复、空态/权威退出不复活，
  以及 Math 确认中 refresh → visible → render 的顺序。
- ArkTS 检查无错误；仅存在既有 unused/deprecation 诊断。完整 Replay 与双 HAP 构建结果记录于阶段 Report。
