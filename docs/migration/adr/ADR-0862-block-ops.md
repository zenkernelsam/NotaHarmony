# ADR-0862 — `rl2`/`td8` 块 op 读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `rl2` = CreateBlock 21 字段：type:cz0、corner:ty0、
  page:cxc、origin:fqa、rotation、scale、**size:qed 必填**、
  textWrap:ive、enableCaption、zIndex:tmf、image:dp5
  ImageAsset、cropRect:bmb、webUrl、mathLatex、
  mathColor:hu1、paper:k3a、双向翻转、
  resizesWidthToFitText、margins:vy7、positionLocked。
  878 `baj.a` 21 参构造器一一对应。
- `td8` = ModifyBlock 19 字段：blocks qo5[] 多目标 +
  setter 语义；**无 type/webUrl/margins 不可改项**；
  `ddg.o` size/origin 联合校验。

## Harmony 决策

块编码 21 槽对齐；创建/修改字段差集（不可改项）
遵守原版边界。

## Parity 状态

等价（872 族闭合）。

## 验证

- `d02-block-ops.mjs`：38/38 通过。
- 全量 Replay 791 文件绿，见 Phase 918 提交。
