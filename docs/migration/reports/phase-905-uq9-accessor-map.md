# Phase 905 报告 — `uq9` 封套读契约实名

## 范围

钉死 op 封套 accessor→偏移全图。纯审计。

## 原版发现

- 七槽位：id@4(qo5 内联,必填)、clientTime@6、
  serverTime@8、audioTime@10、payloadType@12(haa)、
  payload@14(必填)、transientInteraction@16(sdf)。
- 三类读法：内联/标量/间接表。
- haa 前向兼容：越界→NONE。
- 读写公式双向闭合（c(4+2i) ↔ z(off,4+2i)）。

## Harmony 核对

槽位/读法/NONE 回退/必填门对齐。

## 产出

- 证据：`phase-905-uq9-accessor-map.md`
- Fixture：`d02-uq9-accessor-map.mjs`（13/13）
- ADR-0849；全量 Replay 778 文件绿。
