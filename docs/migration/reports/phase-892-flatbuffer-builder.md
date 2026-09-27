# Phase 892 报告 — FlatBufferBuilder 原语层实名

## 范围

钉死全部序列化证据依赖的 `aVar.X` 原语。纯审计。

## 原版发现

- `com/google/flatbuffers/a` = 混淆 FlatBufferBuilder：
  C=startTable、D=startVector、n=endTable、o=endVector、
  z(off,4+2i)=required(field i)、a=addBoolean、e/c/h/j=
  addInt/addByte/addOffset/addStruct、s/t=pad/prep。
- required 公式破解：wa0{0,1,2}、sw9{0,5}、uq9{id,payload}、
  tdf{interactionId}——与 860/862/890 逐点吻合。
- `hu1` = `Color{bitsR,G,B,A}` 4B RGBA 结构。

## Harmony 核对

手写编码器语义一一对应；必填字段门对齐；RGBA 4B 对齐。

## 产出

- 证据：`phase-892-flatbuffer-builder.md`
- Fixture：`d02-flatbuffer-builder.mjs`（18/18）
- ADR-0836；全量 Replay 765 文件绿。
