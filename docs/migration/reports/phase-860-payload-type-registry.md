# Phase 860 报告 — zq9 表↔类型权威注册表与 Op 写入器登记

## 范围

登记 `zq9`（31 条表类↔haa 类型权威映射 + Op 信封写入器）与 `sdf`
瞬态标记副信道，复核 Harmony 常量与解码门。纯审计阶段，无源改动。

## 原版发现

- `zq9` mx7 map：31 条映射恢复全表（墨迹 dm2/wd8、形状 ao2/le8、
  文本 e46/f46/pub/qub/f2c/me8/he8/io1、块 rl2/td8、组 cm2/vd8、
  位置 je8、删除 s83、页面 ln2/ge8、录制 yn2/ke8、元数据 l2d、
  资产 ra0、瞬态 tdf、PDF 字段 ee8、复选框 mqf、对端 yda、
  评论 tl2/ud8）；未映射类 fail-closed。
- `zq9.e` Op 写入器：7 槽表 + id/payload 双 required 标记 ——
  线上 Op 恒载有效负载。
- `sdf` 副信道 = interactionId+timeout 可空标记，非 type-26 负载。

## Harmony 核对

- 31 常量逐值一致；required 门、supports 分发、transient 双恒等槽
  编码器全部对应。无缺口。

## 产出

- 证据：`phase-860-payload-type-registry.md`
- Fixture：`d02-payload-type-registry.mjs`（42/42）
- ADR-0804；全量 Replay 与双 HAP 结果记录于提交。
