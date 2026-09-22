# ADR-0582 — 文本编辑撤销合并轨道（vnf.d op-type→track 指派）

- 状态：Accepted
- Phase 613；对齐 `vnf.d`/`pnf`/`vnf.f,g`/`haa`（decompiled_1.0.3）。

## 背景

原版历史栈 `vnf` 逐 op 入栈 `qnf` 项，每项轨道由 `vnf.d` 按
`uq9.m()`（`haa` op 类型）指派：INSERT_CHAR/INSERT_STRING/
MODIFY_STYLE/MODIFY_PARAGRAPH_STYLE/CLEAR_STYLE →
INSERT_TEXT（2s），REMOVE_CHAR/REMOVE_CHARS → REMOVE_TEXT
（2s），CREATE_INK → CREATE_INK（10ms），其余 op 不可合并。
undo/redo 时 `vnf.f/g` 把栈顶相邻同轨道、相邻时间差 ≤ 轨道窗的
项并为一组。

Harmony 侧 `peekGroup`/`coalesceWindow` 语义与常量早已逐条镜像；
但 `createHistoryMetadata` 仅给 ADD_STROKE 指派 CREATE_INK，
其余 action 一律 NONE。Harmony 文本以整会话 REPLACE_ELEMENT
提交（模型差异：原版逐 op，Harmony 逐会话），因此两次相隔 <2s
的同向编辑在原版会并为一组 undo，Harmony 却给出两步——
用户可见的撤销粒度分叉。

## 决策

1. `createHistoryMetadata` 的轨道指派提取为 `coalesceTrackFor`：
   - `ADD_STROKE` → `CREATE_INK`（haa 15，不变）；
   - `REPLACE_ELEMENT` 且恰好单块、无笔画 → 对
     `beforeElements[0].richText`/`afterElements[0].richText`
     做公共前后缀 diff：
     - 仅新增（removed=0, added>0）→ `INSERT_TEXT`；
     - 仅删除（added=0, removed>0）→ `REMOVE_TEXT`；
     - 混合 diff / 无文本差 → `NONE`；
   - 其余 action（含多块/带笔画 REPLACE、ADD_ELEMENT≈
     CREATE_BLOCK null 轨道）→ `NONE`。
2. 不新增枚举值：`HistoryCoalesceTrack` 早已镜像 pnf 全三轨
   （持久化列 `coalesce_track` 复用）。

## 边界与取舍

- **fail-closed**：混合编辑会话（先插后删等）归 NONE，不会错并；
  相比原版逐 op 拆分（混合会话可能拆成两组）属于欠合并，方向保守。
- **时间近似**：原版比较相邻 op 创建时刻；Harmony 比较会话提交
  时刻，合并窗口被会话时长压缩（更严，欠合并方向），可接受。
- **样式 op 不可达**：MODIFY_STYLE/PARAGRAPH_STYLE/CLEAR_STYLE
  在原版也走 INSERT_TEXT 轨道，但 Harmony 无逐 run 样式 UI
  （格式栏为登记推迟项）；文本 REPLACE 均经 `richText !== text`
  门控，无文本差分支实际不可达，归 NONE。
- **REVIVE_CHARS（haa 11）**：原版明确 null 轨道；Harmony 无独立
  revive action，等价语义由 NONE 默认覆盖。

## 验证

- 桌面 replay：`docs/migration/replays/d02-original-text-coalesce-track.mjs`，19/19。
- `note@default` 构建绿；`note@ohosTest` 构建绿；全量 replay 套件绿。
