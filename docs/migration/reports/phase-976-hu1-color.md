# Phase 976 报告 — hu1 Color RGBA + ao2 required 对账

## 范围

hu1/z5c.P/ao2/x4d。纯审计。

## 原版发现

- `hu1` = Color 4B 内联 RGBA 结构（cmf UByte 分量），
  z5c.P 写器推序 A,B,G,R → 线序 R@0..A@3。
- ao2 required = {page,origin,f5,color} 槽位对账；
  业务校验文案实证。
- 订正：`x4d` 为合成 lambda 类非枚举。

## 产出

- 证据：`phase-976-hu1-color.md`
- Fixture：`d02-hu1-color.mjs`（14/14）
- ADR-0920；全量 Replay 见本提交。
