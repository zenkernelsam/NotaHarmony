# Phase 1470 — PageUp / PageDown 视口翻页滚动（f2 → mfc.s/ad8 通道）

- **阶段**: Phase 1470
- **日期**: 2026-08-10
- **原版版本**: decompiled_1.4.2（APK `com.gingerlabs.notability` 1.4.2）
- **Harmony 落点**: `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  `onCanvasKeyEvent`；`note/src/main/ets/data/OriginalKeyboardChords.ets`

## 原版证据链

### 键码（f2.java 静态区）

```
f2.java:40-60  ——  pa8.a0 = ofk.e(92)；pa8.b0 = ofk.e(93)。
```

- Android `KEYCODE_PAGE_UP = 92`、`KEYCODE_PAGE_DOWN = 93`。
- Harmony 键码：`KEYCODE_PAGE_UP = 2068`、`KEYCODE_PAGE_DOWN = 2069`。

### 分发支（f2.java:253-262）

```java
} else if (pa8.a(db8.n(keyEventB), pa8.a0)) {
    if (lxm.a(db8.o(keyEventB), 1)) {
        mfc mfcVar = jxjVar.c;
        mfcVar.s(mfcVar.j());
    }
} else if (pa8.a(db8.n(keyEventB), pa8.b0)) {
    if (lxm.a(db8.o(keyEventB), 1)) {
        mfc mfcVar2 = jxjVar.c;
        mfcVar2.s(mfcVar2.i());
    }
}
```

- 位于 `!rsi`（非文本编辑）门内的兜底链，DEL 支之后、数字键支之前。
- **无修饰键门**；UP 才动作；DOWN 亦消费（支内无 `b2=0` 落点——
  与该链其它动作支一致的消费语义）。

### 滚动量（mfc.java:347-353 + ad8 byte1）

```java
// mfc.g() = p() − insets：视口内容尺寸（packed w|h）
public final long i() { return ndf.a(0, +(int)(h*0.9f)); }  // 下移
public final long j() { return ndf.a(0, -(int)(h*0.9f)); }  // 上移
// mfc.s(j) → ad8 byte1 协程：mfc.x(mfc.l() + j) 目标位动画滚动
```

- PAGE_UP → 视口上移 90% 视口高；PAGE_DOWN → 下移 90%。x 分量恒 0。
- `ad8` 协程做动画滚动——Harmony `setScroll` 为即时滚动，动画降级
  与 P1468 的 `mfc.s`（DPAD 10% 滚动支）登记一致。

## Harmony 实现

`OriginalKeyboardChords.ets`：

```ts
export const ORIGIN_KEYCODE_PAGE_UP: number = 2068;
export const ORIGIN_KEYCODE_PAGE_DOWN: number = 2069;
export const ORIGIN_KEY_PAGE_SCROLL_FRACTION: number = 0.9;
```

`onCanvasKeyEvent` `!textEditing` 块内（DEL 支之后，保持 f2 链序）：

```ts
if (event.keyCode === ORIGIN_KEYCODE_PAGE_UP ||
  event.keyCode === ORIGIN_KEYCODE_PAGE_DOWN) {
  if (isUp) {
    const pageStep = this.canvasCtx.height * ORIGIN_KEY_PAGE_SCROLL_FRACTION;
    this.viewport.setScroll(this.viewport.scrollX,
      this.viewport.scrollY +
      (event.keyCode === ORIGIN_KEYCODE_PAGE_UP ? -pageStep : pageStep));
    this.onViewportChanged();
  }
  return true;              // DOWN 亦消费（无 b2=0 落点等价）
}
```

## 差异与边界

- 动画：原版 `ad8` 协程动画滚动，Harmony `setScroll` 即时跳变——
  与 P1468 的 `mfc.s` 降级登记一致（同一路径）。
- `mfc.g()` 为 `p()−insets` 的视口内容尺寸；Harmony 取
  `canvasCtx.height`——无 insets 概念下的等价量。
- 文本编辑态透传：`!textEditing` 门等价 `!(Q.m instanceof rsi)`。

## 验证

- `docs/migration/replays/d02-original-page-key-scroll.mjs`：17 项——
  键码/比例 pin、分发结构 pin（UP 门/无修饰门/x 分量恒 0/DOWN 消费）、
  链序 pin、可执行滚动模型（±0.9h、零高视口 no-op）。
- 键盘族 fixture 无回归；`note@default` 构建通过。
