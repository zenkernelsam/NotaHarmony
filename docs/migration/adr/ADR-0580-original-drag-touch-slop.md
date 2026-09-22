# ADR-0580 — 选区拖拽 touch-slop 门控（ycj.e/is7）

- 状态：Accepted
- Phase 611；对齐 `ycj.e`/`is7`/`vo2`/`ha5:232`（decompiled_1.0.3）。

## 背景

原版选择面拖拽走 `ycj.e` 检测器（Compose
`awaitPointerSlopOrCancellation` 族）：`is7.onStartDrag` 于按下、
`onTouchSlopReached` 于位移越 `scaledTouchSlop`、`onDragMove` 仅
在越阈后分发、`vo2` 收尾。slop 之内位移被消费；未越阈抬手按
点按处理。文本面 `pn3`（ha5:232）同族。

Harmony 旧实现：`selectionDrag`/`selectionResize` 按下即生效，
首个 move 增量立即 `moveSelected`/`applySelectionResize`——无
slop 门控，1px 抖动即推动选区。

## 决策

1. 会话态：新增 `selectionGestureSlopAccum`（屏幕空间累计位移）、
   `selectionGestureSlopCrossed`、`selectionGestureLastScreen`；
   `beginSelectionDragSession`/`tryStartSelectionResize` 初始化。
2. `selectionGestureSlopAdvance`：累计 |Δ|，达 **8 屏幕 px** 置
   crossed——注册适配值（原版为密度缩放 dp，代码库既有点按半径
   亦为 8px 量级）。
3. move 门控：drag/resize 未越阈吞事件；drag 越阈首事件取残余
   `(|accum|-8)/zoom`（Compose 消费 slop 语义）；resize 由 anchor
   重算故直接应用当前点。
4. up 门控：未越阈跳过最终增量与 resize 应用——按-抬=点按，
   `isIdentityTransform` 保持恒等不 push undo。
5. 提交/取消路径复位 slop 状态；套索绘制不另加门（已有
   `size>=3` 点数门覆盖小位移）。

## 后果

- 按住选区微抖（<8px）不再推动元素；抬手即点按，零 undo 噪音。
- 拖拽起步手感与原版一致：slop 内静止、越阈后从残余位续拖。
- 8px 为屏幕像素常量；若后续真机手感偏离原版密度缩放值，
  随 P3 真机验证调参（已在 ADR 登记注册适配点）。

## 验证

- `docs/migration/replays/d02-original-drag-touch-slop.mjs`
  23 断言全绿；全量 Desktop Replay 501/501 全绿；
  `note@default` 与 `note@ohosTest` HAP 构建成功。
