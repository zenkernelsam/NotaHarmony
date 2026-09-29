# Phase 1042 报告 — ID 语义细节

## 范围

`ttf`/`utf`/`cxc` 完整语义。纯审计。

## 原版发现

- `ttf` UUID：`a()→byte[]`+`hashCode=I^J`+compareTo/
  equals+canonical toString+K 零哨兵。
- `utf` = wire-UUID（a()+c()+d() 访问器）。
- `cxc.C()` = `J.getInt(I+8)` = 页序@offset+8；
  `xwd.b()`=offset+ByteBuffer 绑定。

## Harmony 决策

UUID 语义+页序 offset-8 保留。

## 产出

- 证据：`phase-1042-id-semantics.md`
- Fixture：`d02-id-semantics.mjs`（10/10）
- ADR-0986；全量 Replay 见本提交。
