# ADR-0830 — `vv7`/`nz9` 页背景构造与序列化

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `nz9` = `C(5)`：`{paper:k3a@0(fag.n0), pdfLayout:sw9@1
  (j7j.c), rotation:Float@2(默认0), size:qed@3(apb.Z),
  quad:vy7@4(fsi.b0)}`。
- `vv7.f` = Kotlin 存根工厂（`&1/2/4/8/16` 各字段默认
  null→`M`→`ybg.c`）；a79.Q 掩码 54 再证「高位=省略
  参数序号」模式（bit5=param5 省略）。
- `vv7.L` = 再序列化器（haj.a/c 嵌入）；`vv7.N(x09)` =
  全文档背景收集（a79.J/D）。
- `vv7` 为混合静态类（Compose/杂项合流）。
- a79.Q = 默认背景：tu1 色纸 + Letter 尺寸。

## Harmony 决策

`encodeOriginalPageBackgroundTableBlob` 五字段序对齐；
默认纸 ↔ PageBackgroundModel；可空入参形态等价。

## Parity 状态

等价（背景线格式 867+886 双层闭合）。

## 验证

- `d02-vv7-nz9-schema.mjs`：19/19 通过。
- 全量 Replay 与双 HAP 构建见 Phase 886 提交。
