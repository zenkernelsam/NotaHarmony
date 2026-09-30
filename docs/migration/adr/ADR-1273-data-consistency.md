# ADR-1273：数据一致性（序列化往返）

## 状态

已接受（Phase 1329）。

## 决策

序列化 = float32-LE 二进制路径 + FlatBuffer op —
— 往返无损（f32 精度+字段完整+op 结构保真）。

## 理由

`OriginalInkPathCodec`（`decodeElements`：element type→
pointCount+每点 getFloat32 LE (x,y)——float32 无损
往返，canonical/replacement/auxiliary/append 变体）+
FlatBuffer op 编解码（`*PayloadEncoder`/`OriginalSynced
OperationFlatBuffer`）—— 序列化往返保真。

## 后果

笔画/op 序列化与原版二进制格式一致（f32 精度+结构
完整）—— 数据一致性保真。
