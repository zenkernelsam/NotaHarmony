# Phase 1019 报告 — ssf 鉴权/会话服务

## 范围

`ssf` 鉴权服务结构+方法形态。纯审计。

## 原版发现

- `ssf{q75,xrf,vs4,pce,sfb,yrd}` + cx6 ctor——
  nr1 鉴权/会话门。
- `b()→ml4`（e Flow）暴露会话状态；
  `e`/`f`(String,String) suspend→`xrf.g` 鉴权端点
  （349/321-inst，decompile-fail）。
- `ml4` = 会话状态接口。

## Harmony 决策

鉴权 fail-closed（OAuth+服务端）；保留状态 Flow
等价物。

## 产出

- 证据：`phase-1019-ssf-auth.md`
- Fixture：`d02-ssf-auth.mjs`（10/10）
- ADR-0963；全量 Replay 见本提交。
