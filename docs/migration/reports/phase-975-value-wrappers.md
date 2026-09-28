# Phase 975 报告 — 值类包装 + jmf/ix4 接口

## 范围

jmf/mmf/tmf/cmf/ix4/nl8/hd/xd8。纯审计。

## 原版发现

- 值类三件套：mmf=int、tmf=long(ZIndex)、cmf=byte。
- `jmf` = ByteList 接口（size/byteAt/迭代器），
  nl8 可变 + hd/xd8 冻结实现——dm2 三条路径
  字节向量的写侧类型实证。
- `ix4` = 元素提供器（invoke() Function1）。

## 产出

- 证据：`phase-975-value-wrappers.md`
- Fixture：`d02-value-wrappers.mjs`（11/11）
- ADR-0919；全量 Replay 见本提交。
