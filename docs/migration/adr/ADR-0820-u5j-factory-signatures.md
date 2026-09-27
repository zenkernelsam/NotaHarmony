# ADR-0820 — `u5j` 操作工厂签名登记

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `u5j` = op 构造工厂，~24 个静态方法，首参一律 `x09`
  文档模型上下文；返回对应 payload 表。
- 签名与 payload 字段对应：H→l2d 八 setter 逐项、n→td8
  十八参、k→s83 四向量、u→he8 携 exc 起止区间对、
  g→dm2 十六参对应 19 槽。
- 参数语义：setter 包装（`?2d`/`nl8`）为可空更新；`xgb`
  为新实体挂钟；`exc` 作位置抽象（cxc 实现）；`v4d`
  形状种类、`mmf` 墨迹序数、`z66` 样式扩展等专项。
- `haj.a(null, nz9, 1, oz9, 16)`（wz9.u）——另族助手，
  末参 16 为写侧常量，语义登记为固定标志位。

## Harmony 决策

各 `Original*Operation`/`PayloadEncoder` 入参形态与工厂
语义对应（可空更新子集 → null-gate 编码）。

## Parity 状态

等价（构造参数契约已登记对照）。

## 验证

- `d02-u5j-factory-signatures.mjs`：29/29 通过。
- 全量 Replay 与双 HAP 构建见 Phase 876 提交。
