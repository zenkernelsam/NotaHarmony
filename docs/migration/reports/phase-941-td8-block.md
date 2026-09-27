# Phase 941 报告 — td8 ModifyBlock 18 槽图

## 范围

第二大 op 表 td8 全槽位钉死。纯审计。

## 原版发现

- 18 槽 setter-wrapped（k2d/y2d/z2d/g2d/p2d/
  n2d）+ Boolean 三态。
- 与 Create 差异：无 margins/type/image/webUrl
  ——创建后不可变确认。

## 产出

- 证据：`phase-941-td8-block.md`
- Fixture：`d02-td8-block.mjs`（19/19）
- ADR-0885；全量 Replay 814 文件绿。
