# Phase 869 报告 — 富文本 op payload 登记

## 范围

登记 `haa` 7–14 八个文本 payload 表（e46/f46/pub/qub/f2c/
me8/he8/io1）字段模式；核对 Harmony 文本 op 层。纯审计阶段。

## 原版发现

- 单点 vs 批量区分：INSERT_CHAR/STRING、REMOVE_CHAR 携单个
  cxc；REMOVE_CHARS/REVIVE_CHARS 携 **cxc 向量**（12B 步长，
  越界 fail-fast）。
- io1 CLEAR_STYLE = {v01×2 范围, boolean, qo5}；
  me8/he8 为样式/段落样式表（857 已登记校验）。
- 目标实体一律 `qo5`；位置一律 `cxc`。

## Harmony 核对

Insert 写手覆盖 insert/remove/revive（visible 分派）；
RichTextStyleOperation 覆盖 12–14；OpTypes 常量齐。

## 产出

- 证据：`phase-869-richtext-op-payloads.md`
- Fixture：`d02-richtext-op-payloads.mjs`（31/31）
- ADR-0813；全量 Replay 与双 HAP 结果记录于提交。
