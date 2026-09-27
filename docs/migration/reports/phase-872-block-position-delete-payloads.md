# Phase 872 报告 — 块/位置/删除 op payload 登记

## 范围

登记 `haa` 22–25 四表（rl2/td8/je8/s83）字段模式；核对
Harmony 写手。纯审计阶段，无源改动。

## 原版发现

- `rl2` CREATE_BLOCK 21 字段富块表。
- `td8` MODIFY_BLOCK 18 槽（缺 f9）：k2d/y2d/ive/z2d/g2d/
  p2d/n2d setter 簇 + Boolean×5。
- `je8` = 单字段位置向量。
- `s83` = 双向四向量：entityDeletes/Undeletes(qo5) +
  pageDeletes/Undeletes(cxc)。

## Harmony 核对

DeleteEntities 编码器字段语义/顺序/元素类型逐项一致；
块/位置编码器齐备。

## 产出

- 证据：`phase-872-block-position-delete-payloads.md`
- Fixture：`d02-block-position-delete-payloads.mjs`（29/29）
- ADR-0816；全量 Replay 与双 HAP 结果记录于提交。
