# ADR-1405: PageUp / PageDown 视口翻页滚动（f2 → mfc.s/ad8 通道）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1470
- **关联**: evidence/phase-1470-page-key-scroll.md
  （`f2:253-262`/`mfc.i,j`/`ad8` 解码）

## 背景

原版键盘兜底链对 PAGE_UP(92)/PAGE_DOWN(93) 实现**视口翻页**：
UP → `mfc.s(mfc.j()/i())` = 视口滚动 ∓90% 视口高（`ad8` 协程动画）；
DOWN 亦消费。无修饰键门、`!rsi` 非文本编辑门。Harmony 此前未接管。

## 决策

- `OriginalKeyboardChords` 新增 `ORIGIN_KEYCODE_PAGE_UP=2068`、
  `ORIGIN_KEYCODE_PAGE_DOWN=2069`、`ORIGIN_KEY_PAGE_SCROLL_FRACTION=0.9`。
- `onCanvasKeyEvent` `!textEditing` 块内新增翻页支（位于 DEL 支之后，
  保持 f2 链序）：UP → `setScroll(scrollY ∓ 0.9×canvasHeight)` +
  `onViewportChanged()`；DOWN 返回 true 消费不动作。
- 不设修饰键门（原版分支谓词无 `db8.r`/`db8.s`）。

## 等价性与边界

- 动画滚动 → 即时滚动：与 P1468 `mfc.s` 降级登记一致（同一滚动
  通道，Harmony viewport 无动画滚动 API）。
- 视口尺寸取 `canvasCtx.height`（原版 `mfc.g()=p()−insets`，
  Harmony 无 insets 差量，差异 ≤ 系统栏像素级）。
- 零高视口时滚动 no-op——与原版 `g()=0 → i()/j()=0` 等价。

## 验证

- `d02-original-page-key-scroll.mjs` 17 项检查全绿（含可执行
  ±0.9h 滚动模型）。
- 键盘族 fixture 无回归；`note@default`、`note@ohosTest` 构建通过。
