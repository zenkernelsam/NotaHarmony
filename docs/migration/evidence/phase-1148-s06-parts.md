# Phase 1148 证据 — s06 payload 部类型

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `pp7{nr5 a}` = 布局引擎包装

`{static pp7 b (EMPTY 常), nr5 a}` —— 实体的 `nr5`
布局引擎包装（shape 布局）。EMPTY 单例兜底。

## `dm2 extends cee implements ka4` = FlatBuffers payload 表

```java
A()→float; B()→tmf; C(fqa)→fqa;    // 源点
D(yyd,i)→yyd; a()→String;          // 名/值
j()→mmf; k()/n()→hu1; l()/m()→Integer
```

形状 create-payload 的序列化字段读（origin/尺寸/名/
标志）——`cee` 表基 + `ka4` 访问 iface。

## `d16{yc6 a..f}` = 6-register 快照集

`{yc6 a,b,c,d,e,f}` —— 形状 6 个变换 reg 的快照
（origin/rot/scale/…×6 的 `yc6` 快照集）。

## `u16{byte I, static nz3 S}` = 字节 enum

`nz3 S` = `$VALUES`/`values()` 数组；`byte I` = ordinal——
实体 kind 变体 enum。

## `s06` 全字段复原

`s06{uq9 createOp, dm2 payload表, d16 6-reg, z4 ?, pp7
布局, k11×2 双界, u16 kind, Integer 子索引}` —— 实体
全解快照。

## Harmony 决策

- payload 部 = FlatBuffers 表(`dm2`) + reg 快照集(`d16`)
  + 布局包装(`pp7`) + kind enum(`u16`)。
- Harmony：表读 + reg 快照 + enum。

## 产出

- fixture `d02-s06-parts.mjs`（10 断言）。
- ADR-1092；中文报告。
