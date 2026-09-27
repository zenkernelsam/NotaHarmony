# Phase 871 报告 — 形状/组 op payload 登记

## 范围

登记 `haa` 18–21 四表（ao2/le8/cm2/vd8）字段模式；核对
Harmony 写手。纯审计阶段，无源改动。

## 原版发现

- `ao2` CREATE_SHAPE：17 槽全图（缺 f5）。
- `le8` MODIFY_SHAPE：f0=目标向量、f8=ife 样式、f10=hu1 颜色、
  f11=Float 边宽、f12=g2d 填充 setter、f14=Boolean 锁定。
- `cm2` CREATE_GROUP = 单字段成员向量；`vd8` = 目标+成员。

## Harmony 核对

ModifyShape 17 槽 vtable 锚点一致（style/color/borderWidth/
fillColor/lock @8/10/11/12/14）；Group 写手输出 qo5 成员
向量+重复校验。

## 产出

- 证据：`phase-871-shape-group-payloads.md`
- Fixture：`d02-shape-group-payloads.mjs`（32/32）
- ADR-0815；全量 Replay 与双 HAP 结果记录于提交。
