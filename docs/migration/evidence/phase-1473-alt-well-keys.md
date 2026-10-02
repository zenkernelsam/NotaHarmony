# Phase 1473 — Alt 井选择键（f2:264-276 → hxi.a → qxi case0）

- **阶段**: Phase 1473
- **日期**: 2026-08-10
- **原版版本**: decompiled_1.4.2（APK `com.gingerlabs.notability` 1.4.2）
- **Harmony 落点**: `NoteCanvasView.ets` `onCanvasKeyEvent` →
  `NotePage.ets` → `EditorViewModel.selectFavoriteColor /
  selectWidthWell / stepFavoriteColor`

## 原版证据链

### 键码与 digit 索引基

- `bd8.java:44`：`i0 = oag.y2(pa8.k..s)` = `ofk.e(8..16)`
  = Android KEYCODE_1..9；`list.indexOf(new pa8(n))` → 0..8。
- `pa8.java:161-162`：`X = ofk.e(71)` = KEYCODE_LEFT_BRACKET、
  `Y = ofk.e(72)` = KEYCODE_RIGHT_BRACKET。

### 分发支（f2.java:264-276，!rsi 门内、!pa8.W 块内）

```java
// 顺序：PAGE_DOWN 支之后、媒体支之前
} else if (!db8.q || db8.r || db8.s || !list.contains(pa8(n))) {
    // —— 非(alt&&!ctrl&&!shift+digit) → 落入后续支
    if (db8.q && !db8.r && db8.s && list.contains(pa8(n))) {
        if (lxm.a(o,1)) hxiVar.a.f(new dxi(list.indexOf(pa8(n))));
    } else if (db8.q && !db8.r && pa8.a(n, pa8.X)) {
        if (lxm.a(o,1)) hxiVar.a.f(new exi(-1));
    } else if (db8.q && !db8.r && pa8.a(n, pa8.Y)) {
        if (lxm.a(o,1)) hxiVar.a.f(new exi(1));
    } else if (db8.r && db8.s && pa8.a(n, pa8.h)) { ...媒体 seek...
    ...
    }
} else if (lxm.a(o,1)) {
    hxiVar.a.f(new bxi(list.indexOf(pa8(n))));   // alt&&!ctrl&&!shift+digit
}
```

- `bxi` = `alt && !ctrl && !shift && digit`；
  `dxi` = `alt && !ctrl && shift && digit`；
  `exi` = `alt && !ctrl && [ / ]`——**shift 不判**（Alt+Shift+[
  同触发步进）。
- 三支 UP 动作、命中即消费（支内无 `b2=0` 落点）。

### 语义（qxi.java case0，hxi.a 事件通道消费端）

```java
// bxi(index): x25 w = e52.s3(index, jyi.B()); w==null → no-op;
//             else jyi.A(w) → k31.X(wsi, g92(w.c, w.d)) → jyi.F 应用
// jyi.B() = x25 色井列表 按 a6n.c(当前工具类型) 过滤 + ttb 排序
// dxi(index): s2k 宽度井列表同型过滤+iyi 排序 → e52.s3(index,…)
//             → k31.Y(wsi, new r2k(s2k.d, s2k.c)) → jyi.F 应用宽度
// exi(delta): i2 = indexOf(x25.d == 当前 g92.c().b)，缺失 0 基；
//             next = floorMod(i2+delta, size) 回卷 → jyi.A 应用
//             listB.isEmpty() → return（no-op）
```

## Harmony 移植

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_LEFT_BRACKET=2059`、
  `ORIGIN_KEYCODE_RIGHT_BRACKET=2060`（`@ohos.multimodalInput.keyCode`
  枚举确认）；`altWellDigitIndex` helper（`alt&&!ctrl` + 共享
  `ORIGIN_TOOL_SELECT_DIGIT_BASE` 索引基）。
- `NoteCanvasView` `!textEditing` 块内（PAGE_DOWN 支后、媒体支前，
  对齐 f2 链序）：

  ```ts
  const altDigit = altWellDigitIndex(event);
  if (altDigit >= 0) {
    if (isUp) {
      if (shift) this.onKeySelectWidthWell(altDigit);
      else this.onKeySelectColorWell(altDigit);
    }
    return true;
  }
  if (keyChordAlt(event) && !ctrl && ([或])) {
    if (isUp) this.onKeyStepColorWell([?-1:1]);
    return true;
  }
  ```

- `NotePage` → `viewModel.selectFavoriteColor / selectWidthWell /
  stepFavoriteColor`（`favoriteColors`/`widthWells` 已按
  `activeToolType` 载入 = `jyi.B()`/`s2k` 过滤等价）。
- `EditorViewModel.stepFavoriteColor(delta)`：`favoriteColors.
  indexOf(brushColor)`（色值匹配 = `x25.d==g92.b`，非存序索引），
  缺失 0 基，`floorMod` 回卷 → `selectFavoriteColor`。

## 差异与残余

- 原版 `hxi.a` 为协程事件通道；Harmony 同步回调，结果等价。
- `jyi.B()`/`s2k` 的 `ttb`/`iyi` 排序键：原版按井序数列排；
  Harmony `favoriteColors`/`widthWells` 已是 trayIndex 顺序表
  ——序等价。
- `bxi`/`dxi` 越界索引：原版 `e52.s3` null → no-op；Harmony
  `selectFavoriteColor`/`selectWidthWell` 越界 return false
  ——等价。
- exi 支原版不判 shift（Alt+Shift+[ 亦步进）——Harmony 忠实保留。

## 验证

- Replay `d02-original-alt-well-keys.mjs`：33 checks
  （键码 pin、helper 门控、shift 分流、[/]方向、消费语义、
  NotePage 接线、VM 语义、可执行门控+回卷模型）。
- `note@default` 编译绿；`note@ohosTest` clean 构建成功。

## 关联

- ADR-1408-alt-well-keys
- 报告 `docs/migration/reports/phase-1473-alt-well-keys.md`
