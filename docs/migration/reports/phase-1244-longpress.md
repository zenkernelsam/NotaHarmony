# Phase 1244 报告 — 长按 fire-vs-cancel

## 完成内容

- `g2`=delay 协程→`gwa` 计时 fire；`b14`=`lh3` dispose
  →`ewa` cancel；`i2`=`k2` 长按状态机（ewa 提前释放/
  gwa fire 双分支）—— `fwa`↔`gwa`/`ewa` = 长按
  fire-vs-release 二分。

## 产出

- evidence `phase-1244-longpress.md`
- fixture `d02-longpress.mjs`（10/10）
- ADR-1188
