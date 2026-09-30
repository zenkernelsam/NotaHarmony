# Phase 1243 报告 — 拖拽事件

## 完成内容

- `bq1`=drag&drop summon（`zo4`/`ap4` 起止 + "Drag &
  Drop" `ns` 协程 + `yp5`/`zp5` 载荷）；`bq4`=focus-
  relay Node（`xp4` onFocusStateChange + `j1(wj8,t76)`
  emit `ap4(zo4)` + `requestFocus` semantics）—— zo4/
  ap4 = 拖拽 start/end。

## 产出

- evidence `phase-1243-drag-events.md`
- fixture `d02-drag-events.mjs`（10/10）
- ADR-1187
