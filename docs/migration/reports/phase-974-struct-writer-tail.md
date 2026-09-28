# Phase 974 报告 — 结构写器尾部四连

## 范围

vfj/fsi/ddj/aa6/vy7。纯审计。

## 原版发现

- `vfj.d`=xq3 24B、`fsi.b0`=vy7 Margins{top,bottom,
  left,right}+ddg.l 负校验、`ddj.b`=ukb 16B、
  `aa6.x0`=ua0 64B 8×long——全部与读侧镜像。
- **z0c(21) 结构注册表 15/15 写器关闭**——写↔读
  字节对称取证链全线完结。

## 产出

- 证据：`phase-974-struct-writer-tail.md`
- Fixture：`d02-struct-writer-tail.mjs`（11/11）
- ADR-0918；全量 Replay 见本提交。
