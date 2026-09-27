# ADR-0849 — `uq9` Op 封套读契约钉死

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- accessor→vtable 偏移：id@4(qo5 内联,必填)、
  clientTime@6(long)、serverTime@8(tmf)、audioTime@10(tmf)、
  payloadType@12(haa byte)、payload@14(cee UOffsetT,必填)、
  transientInteraction@16(sdf UOffsetT,可选)。
- 三类读法：内联结构 `xwd.b`、标量 `get(c(N)+I)`、
  间接表 `b(i)+d(abs)`。
- `haa` 前向兼容：越界→entries[0]=NONE（未知类型不崩）。
- 读公式与写侧 z(off,4+2i) required 双向闭合。

## Harmony 决策

封套解析槽位偏移逐一对应；未知 payloadType→NONE
语义保持；id/payload 必填门对齐。

## Parity 状态

等价（读写双向闭合）。

## 验证

- `d02-uq9-accessor-map.mjs`：13/13 通过。
- 全量 Replay 778 文件绿，见 Phase 905 提交。
