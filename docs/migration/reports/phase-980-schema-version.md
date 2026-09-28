# Phase 980 报告 — SchemaVersion 枚举全史

## 范围

ar6/rgc/q4j/nce。纯审计。

## 原版发现

- `ar6` = SchemaVersion 0–15 完整枚举
  （PRE_SHIPPING→INK_EFFECT），每版本对应一个
  线型特性闸门。
- `rgc.a` = `ar6.K.I` = **15**（INK_EFFECT）——
  写 f7 与读版本闸共用。
- 版本→特性映射首次完整恢复（v5 textbox margins、
  v8 peerInteraction、v12 comments、v14 blockWrap 等）。

## 产出

- 证据：`phase-980-schema-version.md`
- Fixture：`d02-schema-version.mjs`（22/22）
- ADR-0924；全量 Replay 见本提交。
