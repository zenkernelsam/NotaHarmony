# Phase 918 报告 — `rl2`/`td8` 块 op 实名

## 范围

块创建/修改 op 载荷实名。纯审计。

## 原版发现

- rl2=CreateBlock 21 字段全实名——type:cz0/corner:ty0/
  图像 dp5/裁剪 bmb/网页/数学(k3a paper+hu1 mathColor+
  mathLatex)/vy7 margins；size 必填。
- td8=ModifyBlock 19 字段——qo5[] 多目标；type/webUrl/
  margins 不可改；ddg.o 联合校验。

## Harmony 核对

编码对齐；不可改字段边界一致。

## 产出

- 证据：`phase-918-block-ops.md`
- Fixture：`d02-block-ops.mjs`（38/38）
- ADR-0862；全量 Replay 791 文件绿。
