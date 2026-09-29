# Phase 1099 报告 — opId 构造管线 + 浮点打包

## 完成内容

- `rh8.b(i,s)` = opId FlatBuffers 写→绑→校验→池化构造。
- `rh8.a` = float 对→long 打包；`au1.c1`=first()。

## 产出

- evidence `phase-1099-id-construct.md`
- fixture `d02-id-construct.mjs`（10/10）
- ADR-1043
