# ADR-0800 — 操作流 FlatBuffer 序列化层登记与手写编码器 parity 确认

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.4.2` / `decompiled_1.0.3`）

- `defpackage/` 1.4.2 中 133 个文件引用 `com.google.flatbuffers`，其中 65 个含
  `aVarA.D(n)` startObject 调用（表写入器）；最大表 `rbn` D(21)、`wbn` D(20)、
  墨迹表 `fcn`/`n6n` D(19)、复合表 `k2h`（2,2,18,2,19,19）、`y6n` D(18)。
- 1.0.3 基线 91 个 flatbuffer import；`wd8`/`le8`/`td8` 为表读取类（19/17/18 字段）。
- 无 `.fbs` schema 存活；字段容量仅从 `D(n)` 恢复。
- `com.github.luben.zstd` 完整实现打包在 APK，但 app 代码内无 `Zstd.*` 直接调用 —
  压缩是库运行支持，不属于操作线协议。
- 证据文档：`phase-856-flatbuffer-op-tables.md`

## Harmony 决策

- 19 个 `ORIGINAL_*` 操作类型（OpTypes.ets 60–78 连续段）+ 25 个
  `Original*PayloadEncoder` 手写编码器，按 slot 逐字段还原原版字节布局
  （`fields[N]` 数组 + vtable 缺席语义，含 false-boolean 保位）。
- 三处已核对字段数引用与原版 D(n) 完全一致：wd8=19↔fcn/n6n D(19)、
  le8=17、td8=18↔y6n/k2h D(18)。
- 不引入 FlatBuffers 运行库：手写编码器已覆盖全部在用的 19 个操作负载，
  运行时依赖更少且可逐字段审计。

## Parity 状态

- 等价：19/19 个在用操作表均有手写编码器；字段容量引用与原版注册表对齐。
- 非缺口：`k2h` 等多子表写入器对应的复合操作由多个编码器组合表达；
  zstd 非协议层，无需移植。
- fail-closed：原版远程 op-sync 传输层本身 fail-closed（ADR-0794 等），
  本地负载编码保持字节兼容以便历史回放。

## 验证

- `d02-flatbuffer-op-tables.mjs`：18/18 通过（表写入器计数、D(n) 容量、
  1.0.3 读取器存在性、zstd 零调用、19 操作类型、字段数引用、≥15 编码器文件）。
- 全量 Desktop Replay + 双 HAP 构建见 Phase 856 报告。
