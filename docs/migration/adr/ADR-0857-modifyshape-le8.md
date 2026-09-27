# ADR-0857 — `le8` = `ModifyShape` 17 槽读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `le8` = ModifyShape 17 槽：shapes:qo5[]@0、page:cxc@1、
  origin:fqa@2、rotation:k2d@3、scale:y2d@4、
  definitionKind:z4d@5、definition:cee@6、tool:u16@7、
  style:t16@8、tapePattern:ife@9、color:hu1@10、
  borderWidth:Float@11、fillColor:g2d@12、zIndex:tmf@13、
  positionLocked:Boolean@14、inkEffects:tmf@15、
  inkEffectsTinted:Boolean@16。
- 与 CreateShape 差异：qo5[] 多目标首字段、setter 包装
  （k2d/y2d/g2d）、无 smartHighlight/force、inkEffects
  读为 tmf ULong。
- 定义多态双字段保留：z4d@c(14) + z5c.w@c(16)。

## Harmony 决策

ModifyShape 编码对齐；setter 包装与判别子+子表双字段
为形状/墨迹两族共同通则。

## Parity 状态

等价。

## 验证

- `d02-modifyshape-le8.mjs`：20/20 通过。
- 全量 Replay 786 文件绿，见 Phase 913 提交。
