# ADR-0914 — 写侧原语层（FlatBufferBuilder）契约

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`com.google.flatbuffers.a` = R8 混淆 FlatBufferBuilder，
语义与原库 1:1：

- 默认值省略：`{a,c,d,e,f,i,h}` 系 `l||v!=d` 门控；
  **`l`=forceDefaults**——setter 三态强制写的硬件层
  （Phase 966 机制坐实）。
- `C/D/o/n` 生命周期：嵌套禁止、vtable 尾零裁剪、
  `(slots+3)*2` vtable 尺寸、i[]/j 去重。
- `g(i)` rel-uoffset=`(r()-i)+4`；`j` struct 必须内联。
- `z(i,slot)` required 槽检查 → "field N must be set"。
- `p/q/A` finish 门控 + sizedByteArray。
- 池化构造 `a(c8d,bb)` 复用缓冲（Phase 955 闭环）。

## Harmony 决策

Harmony 自研 encode builder 须满足：vtable 尾零裁剪+
去重、required 抛错、forceDefaults 等价、rel-uoffset
公式同。此表即核对规范。

## Parity 状态

等价（规范级）。

## 验证

- `d02-builder-primitives.mjs`：21/21 通过。
