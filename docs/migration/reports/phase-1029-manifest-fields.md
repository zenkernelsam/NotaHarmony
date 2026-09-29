# Phase 1029 报告 — manifest.json 字段 + w59 修正

## 范围

`yk9` manifest 字段 + `w59`/`y59` 续体结构（修正
Phase 1028 回调误判）。纯审计。

## 原版发现

- manifest.json 键：`version`/`noteBundle`/`assets/`
  + wa0 资产元数据。
- `w59 extends ff2` = suspend 续体{ttf,String,lq4,
  Closeable,bool,int,y59 P}——`y59`=外层协程；
  `zk9.a` 的 w59 参数是续体非回调。

## Harmony 决策

manifest 字段保留；suspend→async。

## 产出

- 证据：`phase-1029-manifest-fields.md`
- Fixture：`d02-manifest-fields.mjs`（10/10）
- ADR-0973；全量 Replay 见本提交。
