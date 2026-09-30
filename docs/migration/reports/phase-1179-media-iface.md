# Phase 1179 报告 — 媒体喂帧 iface

## 完成内容

- `zxf`/`nc1` 喂帧/矩阵 iface（解码器→vfc 纹理）；`bpd`
  GL surface 生命周期（Created/Changed/DrawFrame）—
  解码-渲染 producer-consumer 解耦。

## 产出

- evidence `phase-1179-media-iface.md`
- fixture `d02-media-iface.mjs`（10/10）
- ADR-1123
