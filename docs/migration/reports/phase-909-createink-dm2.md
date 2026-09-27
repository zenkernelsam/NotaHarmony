# Phase 909 报告 — `dm2`=CreateInk 20 字段实名

## 范围

实名墨迹创建 op 载荷全部字段读图。纯审计。

## 原版发现

- `dm2` = CreateInk：20 字段全实名——page/origin/
  rotation/scale/tool/style/tapePattern/color/width/
  centerPath/customPath/fillPath/fillColor/styleMap/
  zIndex/audioDuration/nibAngle/nibFlatness/inkEffects/
  inkEffectsTinted。
- 枚举统一 nz3 回退读法；lv2 物化器族。

## Harmony 核对

20 槽编码对齐；位宽语义对齐。

## 产出

- 证据：`phase-909-createink-dm2.md`
- Fixture：`d02-createink-dm2.mjs`（23/23）
- ADR-0853；全量 Replay 782 文件绿。
