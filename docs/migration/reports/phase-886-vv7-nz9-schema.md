# Phase 886 报告 — `vv7`/`nz9` 页背景构造与序列化

## 范围

登记 `nz9` 页背景完整线格式与 `vv7` 工厂/序列化器。
纯审计，无源改动。

## 原版发现

- `nz9` = C(5)：{paper:k3a@0(fag.n0), pdf:sw9@1(j7j.c),
  rot:Float@2(默认0), size:qed@3(apb.Z), quad:vy7@4(fsi.b0)}。
- `vv7.f` = 存根工厂：`&1/2/4/8/16` 各字段默认 null→M→
  ybg.c；a79.Q 掩码 54 再证省略参数序号模式（bit5）。
- `vv7.L` = 再序列化器（haj.a/c 嵌入）；`vv7.N` = 全文档
  背景收集（a79.J/D）。
- a79.Q = 默认背景：tu1 色纸 + Letter 尺寸。
- `vv7` 为混合静态类。

## Harmony 核对

`encodeOriginalPageBackgroundTableBlob` 五字段序对齐；
默认纸 ↔ PageBackgroundModel；可空入参等价。

## 产出

- 证据：`phase-886-vv7-nz9-schema.md`
- Fixture：`d02-vv7-nz9-schema.mjs`（19/19）
- ADR-0830；全量 Replay 与双 HAP 结果记录于提交。
