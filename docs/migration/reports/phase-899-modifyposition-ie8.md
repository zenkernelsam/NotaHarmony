# Phase 899 报告 — `ie8`=ModifyPosition + `tmf`=ULong

## 范围

实名 type-24 载荷与无符号值类家族。纯审计。

## 原版发现

- `ie8` = ModifyPosition（type 24）：{target:qo5,
  page:cxc, origin:fqa, rotation:SetFloat(k2d),
  scale:SetSize(y2d), zIndex:ULong(tmf)}。
- `w0j` 工厂/序列化器 + `qsa.d` applier + `ybg.c` 校验。
- `ddg.e` 校验映射回填。
- `tmf` = ULong 值类——mmf=UInt/ymf=UShort/tmf=ULong
  家族闭环。

## Harmony 核对

六字段编码对齐；setter 包装对齐；zIndex ULong 层序。

## 产出

- 证据：`phase-899-modifyposition-ie8.md`
- Fixture：`d02-modifyposition-ie8.mjs`（15/15）
- ADR-0843；全量 Replay 772 文件绿。
