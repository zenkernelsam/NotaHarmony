# ADR-0856 — `ao2` = `CreateShape` 18 字段读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `ao2` = CreateShape 18 字段：page:cxc@0、origin:fqa@1、
  rotation@2、scale:qed@3、**definitionKind:z4d@4**、
  **definition:cee 子表@5**、tool:u16@6、style:t16@7、
  tapePattern:ife@8、**color:hu1@9（必填）**、
  **borderWidth:float@10（默认 4.0f）**、fillColor:hu1@11、
  zIndex:tmf@12、smartHighlight@13、force:Float@14、
  positionLocked@15、inkEffects:long@16、
  inkEffectsTinted@17。
- 形状定义多态：`z4d` 判别子 → `mpb` 类键 → `z5c.a0`
  分发具体定义子表（矩形/椭圆/线等）；`le8` 修改侧
  同模式（`z5c.w` c(16)）。

## Harmony 决策

CreateShape 编码对齐：判别子+定义子表双字段、
必填 color、borderWidth 默认 4.0。

## Parity 状态

等价（多态分发结构与 uq9 载荷判别同构）。

## 验证

- `d02-createshape-ao2.mjs`：24/24 通过。
- 全量 Replay 785 文件绿，见 Phase 912 提交。
