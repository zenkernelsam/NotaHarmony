# ADR-0814 — 墨迹 op payload 模式登记（类型 15–17）

## 状态

accepted（文档+fixture，无源改动；Harmony 墨迹 op 层已等价）

## 原版契约（`decompiled_1.0.3`）

- zq9 映射：dm2=CREATE_INK、gd=ADD_PATH_ELEMENTS、wd8=MODIFY_INK。
- `wd8` MODIFY_INK 连续 19 字段：f0=qo5 目标向量、f1=cxc、
  f3/f4=k2d/y2d setter、f5=t16 样式、f6=hu1 颜色、f7=Float 宽度、
  f8–f10=Integer×3、f11=g2d、f12=yyd styleMap 向量、f13=tmf、
  f14/15=ymf 路径元素、f16=ife、f17=tmf、f18=Boolean。
- `dm2` CREATE_INK：19 个 vtable 槽（f0–f19 缺 f9），锚点
  f0=cxc、f7=hu1 颜色、f15=mmf 墨迹序数、f18=long。
- `gd`：qo5 目标 + 路径元素向量。

## Harmony 决策

`OriginalModifyInkPayloadEncoder` 写 19 槽 vtable，字段锚点
f5/f6/f7/f12 与原版逐项一致（style/color/width/styleMap），
style 存在时按 `u5j.q` 语义写空 style-map 向量。
`OriginalCreateInk*`/`OriginalAddPathElements*`/`OriginalInkPath*`
/`OriginalInkStyleMapCodec` 覆盖全簇。

## Parity 状态

等价。

## 验证

- `d02-ink-op-payloads.mjs`：34/34 通过。
- 全量 Replay 与双 HAP 构建见 Phase 870 提交。
