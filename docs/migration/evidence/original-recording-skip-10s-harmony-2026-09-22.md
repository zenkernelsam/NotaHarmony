# 原版录音播放 ±10 秒跳转 — Harmony 证据文档

- 日期：2026-09-22
- Phase：569
- 结论：已对齐

## 原版证据（decompiled_1.0.3）

- `d32.java` case 6/7：音频播放器迷你控制条渲染
  `feature_note_toolbox__10secsback_outline` /
  `10secsforward_outline` 图标按钮，a11y 标签
  `cd_rewind_10_seconds`="Rewind 10 seconds"、
  `cd_forward_10_seconds`="Forward 10 seconds"，
  使能态 `ev1.b(uz4Var).c.b`。
- `yna.java`：点击派发 `zoa.a`（Rewind）/ `woa.a`（FastForward）；
  `npa.i` 分派到 `vna.j.s()` / `r()`。
- `uw7.java`（`vna.j` 的承接类）：
  - `s()` 快退：`newPos = max(position - 10000, 0)` → `B(seek)`；
  - `r()` 快进：`newPos = min(position + 10000, duration)` → `B(seek)`。
  - position/duration 取自 `vna.o`/`vna.p`（ms，聚合时间轴）。

## Harmony 落地

- `RecordingPanel.ets` 时间轴行（slider 下位置/时长读数之间）新增居中的
  `SkipButton` 对：`↺ 10s` / `10s ↻`，a11y 用原版文案
  `recording_rewind_10_seconds` / `recording_forward_10_seconds`。
- 点击语义合并为 clamp：
  `target = max(0, min(cumulativeDurationMs, cumulativePositionMs ± 10000))`
  → `onSeek(target)`，与原版 `s()`/`r()` 完全同形（多录音聚合时间轴上
  的 `cumulativePositionMs` 对应 `vna.o`）。
- 使能与守卫复用 slider 的 `controlsEnabled && canSeek()`（
  READY/PLAYING/PAUSED/COMPLETED 且时长 > 0）与
  `photoImportLeaseActive || loading` 点击守卫，视觉透明度随使能联动。

## 差异

- 原版为独立图标资源（`10secsback/10secsforward_outline`）；Harmony 以
  `↺ 10s`/`10s ↻` 文本按钮表达同一语义，a11y 文案与原版一致。
