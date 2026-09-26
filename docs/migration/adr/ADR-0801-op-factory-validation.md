# ADR-0801 — u5j 操作工厂与 ka4 校验契约登记

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- `u5j.java`（1274 行）为操作负载工厂：25 个 `public static` 方法 →
  20 个 FlatBuffer 表类型（wd8/td8/le8/ge8/he8/je8/ke8/me8/vd8/
  pub/qub/cee/f2c/l2d/mqf/gd/rl2/dm2/ln2/ao2/s83），均以 `x09`
  构建器为首参。
- 82 个类实现 `ka4` — `a()` 返回错误字符串或 null 的写入前校验契约，
  覆盖所有操作表与实体/几何子表；33 条 `Cannot/Must/Invalid/Should/No`
  校验消息（其余 return 串为 toString 调试形态）。
- 证据文档：`phase-857-op-factory-validation.md`

## Harmony 决策

- 不引入 `ka4` 式独立校验接口：编码器在编码边界直接 `throw`
  fail-fast（31 条 `original <OP>` 门），等价拒绝非法负载；
  `BinaryOpCodec` 的预算/溢出/magic 门对应 ByteBuffer 边界保护。
- 语义差异登记：原版收集式错误字符串 vs Harmony 首错即抛 —
  同为 fail-closed，无漏门。

## Parity 状态

- 等价：u5j 25 方法→20 表全数映射到 19 个 ORIGINAL_* 编码器 +
  历史陪伴 codec；校验边界同位覆盖。
- 非缺口：ka4 校验的是「构造即非法」负载，Harmony 操作由本地编辑
  产生、编码器即门，等价成立。

## 验证

- `d02-op-factory-validation.mjs`：32/32 通过。
- 全量 Replay 与双 HAP 构建见 Phase 857 报告/提交。
