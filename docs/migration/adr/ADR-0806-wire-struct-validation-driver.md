# ADR-0806 — 内联结构层（xwd）与校验驱动器（ybg.c）登记，tdf 形状核验

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- `xwd`：FlatBuffer **struct** 基座（无 vtable、固定偏移 `b(i,buf)`），
  15 个子类 = Uuid/Id/坐标/颜色/变换内联值类型。
- `ybg.c(ka4)`：校验驱动器 — `a()` 非空即 `ValidationException`
  （MODEL 日志）；`zq9.a()` 解析 Op 后立即调用 → 解析即校验契约。
- `tdf`（type-26）：interactionId@0 required qo5 + replacedByOp@1
  可空 qo5。
- `ree`/`rh8`/`qqi`/`z5c`/`dk4`/`c8d`：序列化管道辅助（类→lambda
  派发、内联写入、payload 解引用、字节流封装）——无独立契约。

## Harmony 决策

- 内联结构以定长读写覆盖：`writeIdentity`（siteId u16+timestamp u32）
  ↔ qo5 8B；`readInlineBytes(0,16)` ↔ utf Uuid 16B。
- 校验门置于解码/编码边界（throw），与 ybg「解析后即校验」同位置。
- `tdf` 编码器逐字节核验通过（36B、vtable 2 槽、required/可空
  presence 语义一致）——860 的待核实项消除，无缺口。

## Parity 状态

等价。无缺口。

## 验证

- `d02-wire-struct-validation-driver.mjs`：21/21 通过。
- 全量 Replay 与双 HAP 构建见 Phase 862 报告/提交。
