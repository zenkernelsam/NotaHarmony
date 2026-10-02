# Phase 1470 报告：PageUp / PageDown 视口翻页滚动

## 原版行为（1.4.2 证据）

键盘兜底链 `f2.java:253-262`（`!rsi` 非文本编辑门内）：

- **键位**：`pa8.a0 = ofk.e(92)` = KEYCODE_PAGE_UP；
  `pa8.b0 = ofk.e(93)` = KEYCODE_PAGE_DOWN。
- **无修饰键门**；UP 动作（`lxm.a(o,1)`）；DOWN 亦消费不动作。
- **滚动量**：`mfc.j()` = `ndf(0, −0.9f×视口高)`（上移）、
  `mfc.i()` = `ndf(0, +0.9f×视口高)`（下移）——x 分量恒 0；
  `mfc.s` → `ad8` 协程动画滚动到 `l()+j`。

## Harmony 缺口

PAGE_UP/PAGE_DOWN 未接管——无翻页滚动通路。

## 实现

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_PAGE_UP=2068`、
  `ORIGIN_KEYCODE_PAGE_DOWN=2069`、`ORIGIN_KEY_PAGE_SCROLL_FRACTION=0.9`。
- `onCanvasKeyEvent` `!textEditing` 块内（DEL 支后，保 f2 链序）：
  UP → `setScroll(scrollY ∓ 0.9×canvasHeight)` + `onViewportChanged()`；
  DOWN 消费不动作。

## 验证

- 新 fixture `d02-original-page-key-scroll.mjs`：17 项（键码/比例
  pin、分发结构、链序、可执行 ±0.9h 滚动模型含零高视口 no-op）。
- `note@default` 构建通过；全量基线与 `note@ohosTest` 收尾验证。

## 遗留差异

- 原版 `ad8` 动画滚动 → Harmony `setScroll` 即时跳变——
  与 P1468 `mfc.s` 降级登记一致。
- `mfc.g()` 含 insets 差量 vs `canvasCtx.height`——≤系统栏像素级。
