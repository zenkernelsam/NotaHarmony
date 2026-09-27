# Phase 878 报告 — 内层构造器 `*0j`/`baj`

## 范围

登记 `u5j` 委托的内层表构造器与 `*0j` 混合静态属性。
纯审计，无源改动。

## 原版发现

- 委托映射：i→haj.a、s/t→r0j.a、u→v0j.b、v→x0j.a(true)、
  r→o0j.a、f→baj.a；各自 `d/e/n` 为序列化器。
- `baj.a` 21 参 + 掩码：bit18→vy7、bit19→z4、bit20→z5；
  u5j.f 传 2883584（bit18+19+21，bit21 省略参数序号）。
- `o0j.a`：xgb→tmf 挂钟包装、list2 防御拷贝、分段负长
  `Got negative length` 置 null。
- `o0j.b/c/d` = 二进制补丁应用器（magic 0xD1FFD1FF、
  version 4）——delta 格式表面登记待查。
- `*0j` 其余方法为混淆合流的无关静态（Bundle/protobuf/
  Compose/协程）。

## Harmony 核对

各 Modify/Create 编码器与内层构造器入参形态对应；派生
默认对齐。

## 产出

- 证据：`phase-878-inner-builders.md`
- Fixture：`d02-inner-builders.mjs`（27/27）
- ADR-0822；全量 Replay 与双 HAP 结果记录于提交。
