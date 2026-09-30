# ADR-1223：OTel 可观测性 wire 层

## 状态

已接受（Phase 1279）—— **fail-closed**。

## 决策

`d4d`/`fn0`/`iz3`/`u8g` OTel Severity+枚举 codec →
Harmony 手写 enum+wire；telemetry 上报 fail-closed
（GMS/Firebase 依赖）。

## 理由

`d4d`=OpenTelemetry Severity（SEVERITY_NUMBER 0-24）；
`fn0`=ProtoEnumInfo；`iz3`/`u8g`=protobuf 枚举/map
codec —— OTLP 日志上报 wire 层（Firebase/GMS
telemetry）。

## 后果

Harmony 遥测 = 手写 enum+wire，上报通道 fail-closed
（无 GMS）—— 枚举语义保真，上报降级。
