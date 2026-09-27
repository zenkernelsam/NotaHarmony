# ADR-0843 — `ie8`=ModifyPosition(type24) + `tmf`=ULong

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `ie8` = `ModifyPosition`（payload type 24，`x0j`
  `new q5(24,ie8,je8)`）：{target:qo5, page:cxc,
  origin:fqa, rotation:k2d=SetFloat, scale:y2d=SetSize,
  zIndex:tmf=ULong}——六可选字段。
- `w0j.a` 工厂（7 参+掩码）/`w0j.d` 序列化器/
  `qsa.d` applier/`ybg.c` 解析后校验。
- `ddg.e` 校验：位置点对+旋转有限+缩放有限。
- `tmf` = Kotlin ULong 值类——无符号家族闭环
  （mmf=UInt、ymf=UShort、tmf=ULong）。

## Harmony 决策

位置修改 op 六字段对齐；SetFloat/SetSize setter 包装；
zIndex ULong 层序语义保持。

## Parity 状态

等价（type-24 全字段实名 + 值类家族闭环）。

## 验证

- `d02-modifyposition-ie8.mjs`：15/15 通过。
- 全量 Replay 772 文件绿，见 Phase 899 提交。
