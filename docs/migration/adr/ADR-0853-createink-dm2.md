# ADR-0853 — `dm2` = `CreateInk` 20 字段读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `dm2` = CreateInk 20 字段：page:cxc@0、origin:fqa@1、
  rotation@2、scale:qed@3、tool:u16@4、style:t16@5、
  tapePattern:ife@6、color:hu1@7、width@8、
  encodedCenterPath@9、encodedCustomPath@10、
  encodedFillPath@11、fillColor:hu1@12、styleMap@13、
  zIndex:tmf@14、audioDuration:mmf@15、nibAngle:ymf@16、
  nibFlatness:ymf@17、inkEffects:long@18、
  inkEffectsTinted:bool@19。
- 枚举读法统一：byte→nz3 条目范围检查→entries[0] 回退。
- `lv2.w/B/E/f0` = 路径/styleMap 向量物化器。

## Harmony 决策

墨迹创建编码 20 槽对齐；枚举 byte 读法、
UShort/UInt/ULong 位宽语义对齐。

## Parity 状态

等价（最大 op 载荷读写双向闭合）。

## 验证

- `d02-createink-dm2.mjs`：23/23 通过。
- 全量 Replay 782 文件绿，见 Phase 909 提交。
