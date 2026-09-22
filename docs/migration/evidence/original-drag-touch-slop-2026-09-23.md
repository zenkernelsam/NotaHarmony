# 证据：选区拖拽 touch-slop 门控（ycj.e → is7.onTouchSlopReached）

日期：2026-09-23 · Phase 611

## 原版调用链（decompiled_1.0.3/sources/defpackage）

`ycj.java:99`——选择/指针面手势检测器：

```java
ycj.e(braVar,
  is7.onStartDrag,
  is7.onTouchSlopReached,
  is7.onDragMove,
  new vo2(13, is7Var, ix4Var),   // 拖拽结束消费
  is7.onResetDrag, ...)
```

`ycj.e` 是 Compose `awaitPointerSlopOrCancellation` 族检测器（与
`ha5.java:232` 文本面 `pn3.onTouchSlopReached/onDragMove/onResetDrag`
同族）。语义：

1. 按下即 `onStartDrag`（对应 `dl1` case2 产出的 `stc`/`htc` 会话
   armed 态——会话在 down 时建立，但坐标位移尚不分发）。
2. 位移累计未达 `ViewConfiguration.scaledTouchSlop`（密度缩放 dp 值，
   常规 ~8dp）前，`onDragMove` 不回调——该段位移被检测器消费。
3. 越过阈值：`onTouchSlopReached` 触发，其后每个 move 事件才进
   `onDragMove`（首个回调只含 slop 之外的残余位移）。
4. 未越阈抬手：`vo2` 收到零位移的拖拽结束——按点按语义处理
   （不产生变换）。

## Harmony 移植前差异

- `beginSelectionDragSession`/`tryStartSelectionResize` 在 down 时
  直接置 `selectionDrag`/`selectionResize`；
- move 分支对每个事件立即 `moveSelected`/`applySelectionResize`——
  1px 抖动就推动选区并在抬起时经 `isIdentityTransform` 检查之外
  的变换路径提交；
- 无 touch-slop 门控。

## 对齐实现

- `selectionGestureSlopAdvance(screenP)`：累计屏幕空间 |Δ|（屏幕 px，
  与缩放无关——slop 是手势/视觉阈值）；达 **8px**（注册适配值，与
  代码库既有点按判定半径 `dist<=8` 同量级；原版为密度缩放 dp）
  置 `selectionGestureSlopCrossed`。
- move 分支：`selectionDrag`/`selectionResize` 先过门控；未越阈
  吞掉事件（drag 同步 `lastDragPoint` 防跳变）。
- drag 越阈首事件按 Compose 残余语义取 `(|accum|-8px)/zoom` 画布
  增量（屏幕位移→画布需除以 zoom）；resize 因由 anchor+当前点
  重算矩形，越阈后直接应用当前点。
- up 分支：`selectionGestureSlopCrossed` 未置位则跳过最终增量
  与 `applySelectionResize`——按-抬=点按，无变换无 undo（commit
  块另有 `isIdentityTransform` 双保险）。
- 提交块与 `cancelActiveInteraction` 复位 slop 状态。

## 覆盖面

`ycj.e` 同一检测器驱动套索/矩形绘制与整选区拖动/角柄缩放/旋转柄：
- 套索小位移已有 `list.size()>=3` 点数门（Phase 607 证据链）覆盖；
- 本 Phase 门控拖动与缩放两条变换路径（共享同一组会话状态字段，
  两分支互斥不会并存）。
