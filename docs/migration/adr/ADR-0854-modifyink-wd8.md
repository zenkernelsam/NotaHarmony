# ADR-0854 — `wd8` = `ModifyInk` 19 字段读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `wd8` = ModifyInk 19 字段：inks:qo5[]@0、page:cxc@1、
  origin:fqa@2、rotation:k2d@3、scale:y2d@4、style:t16@5、
  color:hu1@6、width:Float@7、encodedCenterPath@8、
  encodedCustomPath@9、encodedFillPath@10、
  fillColor:g2d@11、styleMap@12、zIndex:tmf@13、
  nibAngle:ymf@14、nibFlatness:ymf@15、tapePattern:ife@16、
  inkEffects:long@17、inkEffectsTinted:Boolean@18。
- 修改侧通则：rotation/scale/fillColor 用 setter 包装
  （k2d/y2d/g2d）；无 tool 字段；首字段为目标 qo5 集。

## Harmony 决策

ModifyInk 编码与 19 槽图对齐；setter 包装契约与
ie8 ModifyPosition 同模式。

## Parity 状态

等价（修改语义包装层结构对齐）。

## 验证

- `d02-modifyink-wd8.mjs`：23/23 通过。
- 全量 Replay 783 文件绿，见 Phase 910 提交。
