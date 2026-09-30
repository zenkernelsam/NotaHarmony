# ADR-1125：选择态模型（ktc sealed + cmb bounds）

## 状态

已接受（Phase 1181）。

## 决策

`ktc` 密封选择态 4 子型 → Harmony sealed/union 选择
模型：`itc{qo5,ttf}` op-锚定文本选择、`ftc{2×cmb}` 双
bounds、`etc{List,cmb}` 项集、`htc` 子 iface、`pda` PDF
文本 marker；`cmb{float×4}` bounds→Harmony `Rect`。

## 理由

`interface ktc` + `b()→cmb` dispatch + 4 impl + `cmb`
4-float + `e=(0,0,0,0)`。

## 后果

选择模型：op-锚定（CRDT opId）/范围（2 bounds）/
项集/PDF 文本；选择 id `ttf` 全局；Harmony 用 type
union + Rect。
