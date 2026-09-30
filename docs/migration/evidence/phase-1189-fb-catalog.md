# Phase 1189 证据 — ka4 FlatBuffers 表总账（82 implementor）

来源：`defpackage`（grep `implements ka4`）。

## `ka4` = FlatBuffers 生成表 marker iface —— **82 实现**

```java
interface ka4   // 空 marker —— 所有 cee 表的公共契约
```

82 个类 `implements ka4` —— 全 FlatBuffers 生成表（含
全部 op 载荷 + 实体表 + 资产/hash 表 + seq-element 表）。

## 已知子集（实名/obf 映射）

```
uq9   = Op 表（opId+type+payload）
vq9   = CREATE op 载荷
fqa   = 资产/元数据载荷
cxc   = page/seq-id 表
ua0   = asset-hash 表
dm2   = 实体载荷（s06）
r29   = wire bundle 表
vt9   = 实体 op 载荷
s83   = 实体 vector 表
ie8/sw9/q89/qub/ra0/bmb/yn2/akb/v01/ee8/oz8/wd8/
b3d/j2d/o2d/rl2/p9/r60/yq3/xq3/ukb/wa0/cwb/utf/
qo5/gd = 其它生成表
```

## 判定

`ka4` = `cee`-derived **生成表公共 iface**（FlatBuffers
runtime 生成类的 marker）—— 82 表 = 全 schema 实例
（超 32 op 载荷 —— 含实体/资产/元数据/hash/seq 表）。

## Harmony 决策

- `cee`/`ka4` 表类 → Harmony FlatBuffers struct/table
  accessor（同名槽访问）。
- 82 表全 schema 库存 → Harmony `schema.fbs` 重建
  （对齐 `core.flatbuffers.*` 实名：Op/OpAck/SeqId/
  StyleMap/RecordingSegment/Point/Size/ModifyPosition/
  DuplicateOp + Rect/Paper/Paper?/Color/InkStyle/InkTool/
  LayoutMode/BlockWrapSupport/BlockCornerType/
  TextWrapMode/TapePattern/PageBackground/Size）。

## 产出

- fixture `d02-fb-catalog.mjs`（10 断言）。
- ADR-1133；中文报告。
