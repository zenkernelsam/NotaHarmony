# ADR-0910 — `pee` 合并写器与 setter 三态写语义

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `pee` = z0c.invoke() 内匿名 `wx4` 合并类：~28 case
  switch，注册项按 discriminator 分派——setter 家族
  （z1d/g2d/k2d/j2d/m2d/n2d/o2d/p2d/y2d/z2d/a3d）、
  文本五连（pub/qub/f2c）、yn2/ao2/tl2/yda/mqf/io1/
  sdf/tdf/lxc、资产三件套（ra0/akb/wa0）与 zgb/pra。
- setter 写器模式：`C(1)` + `aVar.l=true` 强制写 +
  `x(0,value,default)` + `l=false`。**null=不写槽
  （"未设置"），非 null=强制落盘**——读侧三态的
  写侧镜像。
- `wa0` = AssetMetadata（新类型）：
  `{assetHash:ua0@0, fileName@1, mimeType@2,
  fileSize:mmf@3}`，required 三连 z(4,6,8)。

## Harmony 决策

setter 写侧 = 字段存在性编码（有值必写），与 Harmony
现有可选字段编码等价；`wa0` AssetMetadata 加入资产
元数据完备性清单。

## Parity 状态

等价。

## 验证

- `d02-pee-writer-switch.mjs`：38/38 通过。
- 全量 Replay 见 Phase 966 提交。
