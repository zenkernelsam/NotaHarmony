# ADR-0842 — `ar6` schema 版本里程碑枚举实名

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `ar6` = SchemaVersion short 枚举 16 值：
  PRE_SHIPPING@0 … INK_EFFECT@15（`ar6.K` 当前值，
  `rgc.a` 写入 vt9.schemaVersion）。
- 里程碑→功能映射：CHECKBOX_OP@3、POSITION_LOCK@7、
  PEER_INTERACTION@8、TAPE_PATTERN@9、WRITING_DIRECTION@10、
  CODE_AND_CALLIGRAPHY@11、COMMENTS@12、
  MODIFY_INK_TAPE_PATTERN@13、BLOCK_WRAP@14、INK_EFFECT@15。
- `ymf`=UShort 线上包装（897）。

## Harmony 决策

ops-bundle schema=15；功能门按里程碑序启用——
不得对低 schema 文档误开新 op。

## Parity 状态

等价（版本-功能映射全实名）。

## 验证

- `d02-ar6-schema-enum.mjs`：20/20 通过。
- 全量 Replay 771 文件绿，见 Phase 898 提交。
