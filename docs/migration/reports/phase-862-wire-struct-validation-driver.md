# Phase 862 报告 — 内联结构层与校验驱动器登记 + tdf 核验

## 范围

FlatBuffer 线层收尾：`xwd` struct 基座（15 成员）、`ybg.c` ka4
校验驱动、`tdf` 逐字节核验、序列化管道辅助类登记。纯审计。

## 原版发现

- `xwd` = 固定偏移 struct 基座（无 vtable），15 个内联值类型
  （Uuid/Id/坐标/颜色等）。
- `ybg.c` = ka4→ValidationException 驱动；`zq9.a` 解析后立即校验。
- `tdf` = TransientInteractionEnded{interactionId@0 req qo5,
  replacedByOp@1 opt qo5}。
- `ree`（类→lambda 派发+fail-closed）、`rh8`/`qqi`/`z5c`/`dk4`/`c8d`
  管道辅助登记。

## Harmony 核验

- `OriginalTransientInteractionPayloadEncoder` 与 tdf **逐字节一致**
  （36B、vtable presence 槽、双 8B 恒等槽）——860 疑点消除。
- 内联结构读写 + 校验门同位覆盖。无缺口。

## 产出

- 证据：`phase-862-wire-struct-validation-driver.md`
- Fixture：`d02-wire-struct-validation-driver.mjs`（21/21）
- ADR-0806；全量 Replay 与双 HAP 结果记录于提交。
