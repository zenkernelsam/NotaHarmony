# Phase 1239 报告 — 计时手势事件

## 完成内容

- `hwa`=计时事件分类 iface；`fwa`=计时 start（long
  时间戳）；`gwa`/`ewa`=两种终态（都包 `fwa`→e71 出栈）
  —— press-hold 长按计时手势（fire vs release 二分）。

## 产出

- evidence `phase-1239-timed-events.md`
- fixture `d02-timed-events.mjs`（10/10）
- ADR-1183
