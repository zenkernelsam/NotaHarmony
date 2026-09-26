# Phase 857 报告 — u5j 操作工厂与 ka4 校验契约登记

## 范围

登记原版 `u5j.java` 操作负载工厂全貌与 `ka4` 写入前校验接口，
核对 Harmony 编码器边界等价性。纯审计阶段，无源改动。

## 原版发现

- `u5j` = 操作工厂：25 个静态方法 → 20 个 FlatBuffer 表类型
  （墨迹 wd8、块 td8、形状 le8、页面 ge8、组/删除/元数据 he8-ke8、
  创建复合 me8、结构 pub/qub/cee、实体 f2c/l2d/mqf、
  文本/变换 gd/rl2/dm2、位置/插入 ln2/ao2、样式 s83、vd8）。
- `ka4` 校验接口 82 实现，`a()` 返回错误串或 null；
  33 条真实校验消息（同目标两次、0 页/0 元素、类型错位等）。
- 校验语义为写入前收集式错误返回。

## Harmony 核对

- 19 个 ORIGINAL_* 操作 + 陪伴 codec 覆盖 u5j 全部表类型。
- 31 条编码器 throw 门 + BinaryOpCodec 边界门 — 同边界等价
  fail-closed（fail-fast 替代收集式返回）。
- 无编码缺口，无校验漏门。

## 产出

- 证据：`phase-857-op-factory-validation.md`
- Fixture：`d02-op-factory-validation.mjs`（32/32）
- ADR-0801；全量 Replay 与双 HAP 结果记录于提交。
