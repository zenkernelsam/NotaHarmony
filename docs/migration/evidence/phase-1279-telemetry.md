# Phase 1279 证据 — d4d/fn0/iz3/u8g OTel 严重度+枚举编解码

来源：`defpackage/{d4d,fn0,iz3,u8g,g2b}.java`。

## `d4d` = OpenTelemetry `Severity` 枚举持有者

```java
fn0 a = SEVERITY_NUMBER_UNSPECIFIED(0)
fn0 b..e = TRACE(1..4);  f..i = DEBUG(5..8)
j..m = INFO(9..12);    n..q = WARN(13..16)
r..u = ERROR(17..20);  v..x = FATAL(21..24)
```

→ OTel 日志 `LogRecord.severityNumber` 全量枚举
（OTLP 日志协议）。

## `fn0` = `ProtoEnumInfo{enumNumber, name}`

`{int a, String b}` + toString=`ProtoEnumInfo{...}` —
— proto 枚举值包装（telemetry proto codegen）。

## `iz3 extends g2b` = protobuf 枚举/map 编解码器

```java
iz3(Class, u8g) {
    c(t71)/d(vw7)/e(uw7)/g(obj)/j(i)→u8g
}
```

→ protobuf-lite 的 `EnumLite`/map-field codec —
— `u8g`=`Internal.EnumLite`，`t71`/`vw7`/`uw7`=wire。

## `u8g` = protobuf `Internal.EnumLite` iface。

## 语义

**可观测性 wire 层** —— OTel Severity（日志严重度
0-24）+ proto 枚举 codec —— Firebase/GMS telemetry
用 OTLP 日志协议上报（`fn0` ProtoEnumInfo 是 codegen
枚举描述符）。

## Harmony 决策

OTel Severity+proto 枚举 → Harmony 手写 enum+wire —
— telemetry 上报 fail-closed（GMS/Firebase 依赖）
但枚举语义保真。

## 产出

- fixture `d02-telemetry.mjs`（10 断言）。
- ADR-1223（fail-closed）；中文报告。
