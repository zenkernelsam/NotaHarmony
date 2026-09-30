# ADR-1220：打包 ID + FlatBuffers 解码 + GraphQL op

## 状态

已接受（Phase 1276）。

## 决策

`mmf`/`njj`/`ft9`/`tr2` → Harmony `ID{uuid,type:uint}`+
二进制解码+GraphQL 操作。

## 理由

`mmf`=无符号 int value-class；`njj.A`=FlatBuffers→`qo5`
实体解码器；`ft9`=GraphQL Operation（id/name/doc）；
`tr2`=Apollo CustomScalarAdapters —— 实体寻址+同步
协议桥。

## 后果

Harmony 实体 ID+op 编码 = 类型化 ID+FlatBuffers 解码+
GraphQL —— 寻址+同步语义保真。
