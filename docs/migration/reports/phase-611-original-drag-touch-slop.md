# Phase 611 — 选区拖拽 touch-slop 门控（ycj.e → is7）

- 日期：2026-09-23
- 结果：已实现对齐
- 证据：`docs/migration/evidence/original-drag-touch-slop-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0580-original-drag-touch-slop.md`
- Replay：`d02-original-drag-touch-slop.mjs`（23 项断言）

## 背景

原版选择面拖拽由 `ycj.e` 检测器驱动（`ycj.java:99`：
`is7.onStartDrag/onTouchSlopReached/onDragMove` + `vo2` 收尾），
Compose `awaitPointerSlopOrCancellation` 族语义——位移未达
scaledTouchSlop 前 onDragMove 不分发，slop 之内位移被消费，
首个回调只含残余位移；未越阈抬手按点按处理。

Harmony 旧实现：选区拖动/角柄缩放在 down 时即生效，首个 move
增量直接应用——1px 抖动也推动选区，与原版 slop 门控不符。

## 实现

- 会话态 `selectionGestureSlopAccum/Crossed/LastScreen`；
  拖动与缩放会话初始化时重置。
- `selectionGestureSlopAdvance`：累计屏幕 |Δ|，8px 越阈
  （注册适配值）。
- move 门控：未越阈吞事件；drag 越阈首事件按残余
  `(|accum|-8)/zoom` 应用；resize 由 anchor 重算直接应用。
- up 门控：未越阈跳过最终增量——点按无变换无 undo。
- 提交/取消路径复位；套索小位移沿用 `size>=3` 点数门。

## 验证

- Replay 新增 23 断言；全量 Desktop Replay 501/501 全绿。
- ArkTS 静态检查：`note@default`、`note@ohosTest` 构建 0 错误。
- 手感语义：slop 内静止 → 越阈续拖；按-抬 = 点按。
