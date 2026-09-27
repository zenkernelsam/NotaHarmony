# Phase 912 报告 — `ao2`=CreateShape 18 字段实名

## 范围

形状创建 op 载荷实名 + 定义多态机制。纯审计。

## 原版发现

- `ao2` = CreateShape：18 字段全实名；**f4=z4d
  定义种类判别子，f5=cee 定义子表**——判别子经
  `mpb` 类键驱动 `z5c.a0` 分发到具体形状定义类。
- color 必填（o14 required）；borderWidth 默认 4.0f。
- `z5c.w` 同模式服务 ModifyShape（le8 c(16)）。

## Harmony 核对

编码对齐；多态判别+子表模式与 uq9 同构。

## 产出

- 证据：`phase-912-createshape-ao2.md`
- Fixture：`d02-createshape-ao2.mjs`（24/24）
- ADR-0856；全量 Replay 785 文件绿。
