# Phase 1037 报告 — x09 文档模型 + m09 默认常量

## 范围

`x09` marker + `m09` companion + `a79`/`tu1` 常量 +
`m09.a` 物化器。纯审计。

## 原版发现

- `x09` = marker iface（218+ impl——所有文档实体）。
- `m09` = companion 默认常量：qed size/vy7 margins/
  hu1 color/vv7 复合/a79.P float + `qed.d()/768` 缩放。
- `m09.a(r29,cl9)` = bundle→model 物化器
  （ze9+lv2.T ops→cl9）。

## Harmony 决策

x09→base iface；常量+物化器保留。

## 产出

- 证据：`phase-1037-document-model.md`
- Fixture：`d02-document-model.mjs`（10/10）
- ADR-0981；全量 Replay 见本提交。
