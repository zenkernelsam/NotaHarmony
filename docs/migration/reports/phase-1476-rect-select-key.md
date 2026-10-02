# Phase 1476 报告 — Ctrl+Shift+T 视口中心矩形选区

## 原版行为（decompiled_1.4.2）

`f2.java:230-238`（`!rsi` 文本编辑门内、`!pa8.W` 块内、Ctrl+D 支后
M/I 支前）：

- **Ctrl+Shift+T**（`pa8.G = ofk.e(48)` = KEYCODE_T，Harmony 2036）：
  KeyUp + `u7b.g` 键盘使能旗 + `!bd8.U.r`（`c5i`
  isEffectivelyEnabled 派生旗）→
  - `exj.c()` 取视口中心（画布坐标）；
  - `sbe(cx-120, cy-60, cx+120, cy+60)` = **240×120 画布矩形**；
  - `ome.a()` 清当前选区；
  - `ome.g.l(null, u64(sbe))` 发布矩形选区请求 → `r3b.c(sbe,msf)`
    → `p3b` 协程矩形相交命中选区。
- 与拖拽矩形完成路径（`ch1:55-68` `z3` 支）共用同一 `u64` 通道；
  支内无 `b2=0` → DOWN 吞键不动作。

## Harmony 移植

- `ORIGIN_KEYCODE_T = 2036`（SDK 枚举核实）+ 符号对照注释；
- `onCanvasKeyEvent` `!textEditing` 块内 DPAD nudge 支后、M/I 支前
  （对齐 f2 链序 230→240）：`ctrl&&shift&&T` 命中即消费、UP 动作；
- `applyKeyboardRectSelection()`：
  `viewport.screenToCanvas(画布中心)`（=`exj.c()`）→
  `beginSelection(RECTANGLE, 左上角)`（重置 id 集 ≡ `ome.a()`）→
  `updateSelection(右下角)` 扩界 240×120 → `finalizeSelection(...)`
  复用拖矩形同一命中核（rectIntersects/selectionPath + strokeHit
  lambda）；零命中 → `deselect()` + `selectionVisible=false`。

## 差异登记

- `bd8.U.r`（c5i isEffectivelyEnabled 派生旗）未移植 → 恒放行；
- `u7b.g` 恒真近似（同 P1468/1475）；
- `ome.g` 异步请求槽 → 同步直调同核（ADR-1411）。

## 验证

- `d02-original-rect-select-key.mjs`：**21 checks OK**；
- `note@default` 构建绿（P1476 态）；
- 全量基线与 `note@ohosTest` 见提交前验证节。

## 文件

- `note/src/main/ets/data/OriginalKeyboardChords.ets`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `docs/migration/replays/d02-original-rect-select-key.mjs`
- `docs/migration/evidence/phase-1476-rect-select-key.md`
- `docs/migration/adr/ADR-1411-rect-select-key.md`
