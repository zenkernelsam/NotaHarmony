# ADR-0836 — `a` = FlatBufferBuilder 原语层 + `hu1` = Color

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`com/google/flatbuffers/a.java`）

- `a` = 混淆 FlatBufferBuilder：`C`=startTable、
  `D`=startVector、`n`=endTable、`o`=endVector、
  `z(off,4+2i)`=required(field i)、`a`=addBoolean、
  `e/c/h/j`=addInt/addByte/addOffset/addStruct、
  `s/t`=pad/prep、`r/B`=offset/slot、`q`=完成守卫。
- required 公式 4+2·字段号统一破解：wa0 必填 {0,1,2}、
  sw9 必填 {0,5}、uq9 必填 {id,payload}、tdf 必填
  {interactionId}——与历史证据逐点吻合。
- `hu1` = `Color{bitsR,bitsG,bitsB,bitsA}` 4B RGBA 结构。

## Harmony 决策

手写编码器的 prep/slot/vtable 语义 = 原语集一一对应；
必填字段门对齐 required 断言；颜色 RGBA 4B 对齐。

## Parity 状态

等价（原语层逐方法实名，required 公式统一验证）。

## 验证

- `d02-flatbuffer-builder.mjs`：18/18 通过。
- 全量 Replay 765 文件绿，见 Phase 892 提交。
