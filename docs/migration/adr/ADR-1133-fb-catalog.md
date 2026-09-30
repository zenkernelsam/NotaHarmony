# ADR-1133：ka4 FlatBuffers 表总账（82）

## 状态

已接受（Phase 1189）。

## 决策

`ka4` = `cee`-derived **生成表公共 marker iface** —
82 实现 = 全 schema 实例（超 32 op 载荷 —— 含实体/
资产/hash/seq/元数据表）→ Harmony `schema.fbs` 重建
+ FlatBuffers accessor（槽访问对齐）。

## 理由

`interface ka4` + grep `implements ka4` = 82；`uq9`/`vq9`/
`fqa`/`cxc`/`ua0`/`dm2`/`r29`/`vt9`/`s83`/`ie8`/… 全实现。

## 后果

Harmony schema = 82 表（`core.flatbuffers.*` 实名指导：
Op/OpAck/SeqId/StyleMap/RecordingSegment/Point/Size/
ModifyPosition/DuplicateOp + Rect/Paper/Color/InkStyle/
InkTool/LayoutMode/BlockWrapSupport/BlockCornerType/
TextWrapMode/TapePattern/PageBackground/Size…）。
