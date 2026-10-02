# Phase 1475 报告 — Ctrl+Shift+M/I 插入和弦

## 原版行为（decompiled_1.4.2）

`f2.java` 键盘分发兜底链（`!rsi` 文本编辑门内、`!pa8.W` 块内）：

- **Ctrl+Shift+M**（`pa8.D = ofk.e(41)` = Android KEYCODE_M，
  Harmony 2029）：KeyUp + `u7b.g` 键盘使能旗 →
  `ea1.p(mc8.a)` = **InsertMath** 事件；
- **Ctrl+Shift+I**（`pa8.C = ofk.e(37)` = KEYCODE_I，
  Harmony 2025）：KeyUp + `u7b.g` → `ea1.p(nc8.a)` =
  **InsertPhoto** 事件；
- 两支命中即消费（支内无 `b2=0`）——DOWN 吞键不动作；
- 链序：Ctrl+Shift+T(230) → M(240) → I(244) → DEL(247)。

`mc8`/`nc8` 为 `tc8` 事件单例（toString = "InsertMath"/"InsertPhoto"），
经事件总线由编辑器消费端打开数学插入 / 图片导入 UI。

## Harmony 移植

- `OriginalKeyboardChords.ets`：新增 `ORIGIN_KEYCODE_M = 2029`、
  `ORIGIN_KEYCODE_I = 2025` 及原版符号对照注释；
- `NoteCanvasView`：新增 `onKeyInsertMath`/`onKeyInsertPhoto`
  props；分发支置于 `!textEditing` 块内 DPAD nudge 支后、DEL 支前
  （对齐 f2 链序），`ctrl&&shift&&(M|I)` 命中即消费、UP 回调；
- `NotePage`：回调直通工具栏同一插入管线——
  `mathInsertSignal++` / `photoImportLeaseActive = true` +
  `photoInsertSignal++`，同租约门
  （photoImportLeaseActive/pageOperationBusy/historyPending/
  pageStructureLeaseActive）。

## 差异登记

- `u7b.g` 组合使能旗不移植（恒真近似，P1468 同例）；
- 事件总线解耦 → 直调管线，单 Page 内语义等价。

## 验证

- `d02-original-insert-keys.mjs`：**19 checks OK**；
- `note@default` clean 构建绿（P1475 态）；
- 全量基线与 `note@ohosTest` 见下方基线节。

## 文件

- `note/src/main/ets/data/OriginalKeyboardChords.ets`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `note/src/main/ets/ui/editor/NotePage.ets`
- `docs/migration/replays/d02-original-insert-keys.mjs`
- `docs/migration/evidence/phase-1475-insert-keys.md`
- `docs/migration/adr/ADR-1410-insert-keys.md`
