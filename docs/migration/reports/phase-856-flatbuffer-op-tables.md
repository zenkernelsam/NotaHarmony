# Phase 856 报告 — 操作流 FlatBuffer 序列化层登记

## 范围

登记原版（1.4.2 为基准、1.0.3 为移植基线）FlatBuffer 操作序列化面，并核对
Harmony 手写编码器的字段容量引用。纯审计阶段，无源改动。

## 原版发现

- `com/gingerlabs/notability/core/flatbuffers` 仅剩 `ValidationException`；
  真实序列化面在 `defpackage` 混淆产物。
- 1.4.2：133 个文件 import flatbuffers，**65 个表写入器**（`D(n)` startObject）。
  最大表：`rbn` D(21)、`wbn` D(20)、`fcn`/`n6n` D(19)（墨迹）、`k2h` 六子表
  （2,2,18,2,19,19）、`y6n` D(18)、`hw5` D(15)；`yag` 390 个 D 调用为批量向量
  构建器。
- 1.0.3：91 个 flatbuffer import；`wd8`/`le8`/`td8` 为表读取类。
- 无 `.fbs` 存活；`zstd` 实现打包但 app 代码零直接调用 — 非协议层。

## Harmony 核对结果

- 19 个 `ORIGINAL_*` 操作类型（60–78）+ 25 个手写 `Original*PayloadEncoder`。
- 字段数引用与原版注册表一致：`wd8` 19↔`fcn`/`n6n` D(19)、`le8` 17、`td8` 18↔`y6n`/`k2h` D(18)。
- **无真实编码缺口**；zstd 属厂商支持不构成缺口。

## 产出

- 证据：`phase-856-flatbuffer-op-tables.md`
- Fixture：`d02-flatbuffer-op-tables.mjs`（18/18）
- ADR-0800；全量 Replay 与双 HAP 构建结果记录于提交。

## 备注

- 初期一次 "操作类型覆盖 = 0" 的朴素检索为方法学假象（未计入编码器文件名/
  枚举/注释引用），已通过注册表交叉核对纠正。
