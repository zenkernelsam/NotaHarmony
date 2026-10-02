# ADR-1387：矩形选区进行中手势画指针轨迹而非矩形轮廓

## 状态

已实施（Phase 1452）。

## 背景

Phase 1447 引入进行中选区手势渲染时，矩形模式呈现为当前 `rect` 归一化
轮廓，并登记"语义等价"差异。继续深挖 1.4.2 反编译证据后证明该差异
不成立：

- `hsf`（进行中手势状态）含 `a`=指针轨迹点列、`b`=累积 bounds，
  **lasso/rect 两模式共用同一追踪器**（`lr` case13：每点追加 `a` +
  扩展 `b`）。
- `sen:1051 → gsf.d(hsf.a, open)`：进行中恒画指针原始轨迹——矩形
  模式下用户看到的是沿拖行路径的蚂蚁线（通常近似斜线），不是矩形
  轮廓。
- `z6c case6`：完成时 `isf.k = isf.l = hsf.a`——矩形绘制选区的
  完成态 ghost 轨迹同样是指针轨迹。

## 决定

1. `SelectionState.lassoPoints` 兼任 `hsf.a`：`updateSelection` 两模式
   均逐点追加；`rect` 继续担任 `hsf.b`（命中判定与 `drawnBounds`）。
2. `renderSelectionGestureTrail` 移除矩形轮廓分支，统一描边
   `lassoPoints`（`gsf.d` 语义：开放 path、4dp/zoom、9dp/zoom 虚线、
   相位行进）。
3. `renderSelectionTrailGhost` 去除 lasso 模式门——矩形绘制选区完成
   后 ghost 呈现同一指针轨迹（`isf.k`）。

命中语义不变：rect 模式 `drawnBounds`/`selectionPath`/`pointInPolygon`
回退均按模式门控，仍走 `rect` 界。

## 后果

- 矩形选区手势视觉与原版一致（拖行斜线蚂蚁线，而非矩形框）。
- `lassoPoints` 语义泛化为"指针轨迹"（hsf.a），注释已标注。
- fixture `d02-original-selection-outline-render` 更新为钉两模式共用
  轨迹 + ghost 不限模式。
