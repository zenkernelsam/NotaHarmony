# Phase 946 报告 — o0j.f ModifyInk 写器

## 范围

第二大写端映射钉死。纯审计。

## 原版发现

- o0j.f：C(19)+f0-f18，f0 inks required；
  写端字段序与 910 读端逐项镜像。
- 枚举强制写机制（l=true）：byte 枚举 =0
  也须写出。
- 关联类型：xd8 路径 lambda、apb.Y、z5c.P、
  rz1.h0/g0。

## 产出

- 证据：`phase-946-o0j-wd8-writer.md`
- Fixture：`d02-o0j-wd8-writer.mjs`（11/11）
- ADR-0890；全量 Replay 819 文件绿。
