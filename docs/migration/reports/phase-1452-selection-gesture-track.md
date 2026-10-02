# Phase 1452 报告：矩形选区手势指针轨迹渲染纠偏（hsf.a 共用追踪器）

## 触发

Phase 1447 曾将"矩形模式进行中画矩形轮廓"登记为语义等价差异。本轮按
交接审计流程深挖 1.4.2 反编译证据后，证伪该等价性并纠偏。

## 原版证据链

1. **`hsf`**（进行中选区手势，hsf.java）：`a`=指针轨迹 List、`b`=累积
   bounds `sbe`、`c`=内容令牌 `bpj`。lasso/rect **无类型分支**。
2. **`lr` case13**（lr.java:95-101）：每次 move 变换 `hsf` 为
   `a'=a+[point]`、`b'=b∪point`——矩形模式同样逐点追加轨迹。
3. **`sen:1051 → gsf.d`**：进行中渲染唯一消费 `hsf.a`，开放 path 描边
   蚂蚁线（4dp/9dp/zoom、600ms 相位、#FF4278FF）。
4. **`z6c` case6**（z6c.java:140-154）：完成时
   `isf(b,b,b,…,k=hsf.a,l=hsf.a,…)`——轨迹快照即 `hsf.a`，矩形绘制
   选区的 ghost 同样是指针轨迹；空命中 `set.isEmpty()` → 丢弃。
5. **`mud` case7 / `zf3`**（P1445）：`hsf.b` 累积 bounds 为点除/命中
   判定域——对应 Harmony `rect`。

## Harmony 修改

| 文件 | 改动 |
|------|------|
| `SelectionTool.ets` | `updateSelection` 两模式均 `lassoPoints.push`（=hsf.a）；rect 模式继续维护 `rect`（=hsf.b） |
| `NoteCanvasView.ets` | `renderSelectionGestureTrail` 删除矩形轮廓分支，恒画 `lassoPoints` 开放轨迹 |
| `NoteCanvasView.ets` | `renderSelectionTrailGhost` 去除 `mode===LASSO` 门（isf.k 两模式同为轨迹） |

## 验证

- Replay `d02-original-selection-outline-render`：22 项全绿（新增 5 项
  Phase 1452 断言：两模式轨迹记录、无矩形轮廓分支、ghost 不限 lasso、
  命中消费模式门保持）。
- 全量 Desktop Replay 基线：待跑。
- `note@default` / `note@ohosTest` HAP 构建：待跑。

## 遗留

- 原版 `hsf` 手势可能存在点采样节流（原版触摸事件本身）；Harmony 逐
  touchMove 记录，点数粒度差异不具用户可见性。
- 矩形模式完成后的 ghost（闭合蚂蚁线轨迹）与原版 `isf.k` 一致——本
  Phase 顺带修正。
