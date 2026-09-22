# Phase 613 — 文本编辑撤销合并轨道（vnf.d op-type→track）

## 原版证据

- `vnf.java:56-82`（方法 `d`）：历史项轨道按 `uq9.m()`（`haa` op
  类型）指派——ordinal 7/8/12/13/14（INSERT_CHAR/INSERT_STRING/
  MODIFY_STYLE/MODIFY_PARAGRAPH_STYLE/CLEAR_STYLE）→ `pnf.J`
  = INSERT_TEXT；ordinal 9/10（REMOVE_CHAR/REMOVE_CHARS）→
  `pnf.K` = REMOVE_TEXT；ordinal 15（CREATE_INK）→ `pnf.L`
  = CREATE_INK；其余（含 ordinal 11 REVIVE_CHARS）→ null。
- `pnf.java:24-28`：INSERT_TEXT/REMOVE_TEXT 各 2 秒，CREATE_INK
  10 毫秒。
- `vnf.java:489-516/562-599`（`f`/`g`）：undo/redo 分组——栈顶项
  无条件入组，逐项要求候选轨道非空、与锚轨道相等、相邻时间差
  ≤ 候选轨道窗；`h()` 仅刷新 canUndo/canRedo。
- `haa.java`：op 类型枚举 ordinal 对照表。

## 排查结论

Harmony `peekGroup`/`coalesceWindow` 的分组语义与三常量早已
逐条镜像（含 NONE→`window<0` 断开、锚点先入组）；但
`createHistoryMetadata` 只给 ADD_STROKE 指派 CREATE_INK。
Harmony 文本以整会话 REPLACE_ELEMENT 提交（原版逐 op），
跨会话快速同向编辑无法按原版并组——撤销粒度分叉。

## 修复

`UndoRedoManager.ets`：新增 `coalesceTrackFor(action)`，
`createHistoryMetadata` 改为调用之。REPLACE_ELEMENT 单块、
无笔画时按 richText 公共前后缀 diff 分类：仅新增 →
INSERT_TEXT，仅删除 → REMOVE_TEXT，混合/无差 → NONE；
ADD_STROKE 仍 CREATE_INK；其余一律 NONE（fail-closed，
含 ADD_ELEMENT≈CREATE_BLOCK null 轨道、带笔画/多块
REPLACE）。

模型差异已登记：会话提交时刻代替 op 创建时刻（窗口更严）、
混合会话欠合并、样式 op 无对应 UI 不可达。

## 验证

- 新增 replay `d02-original-text-coalesce-track.mjs`：19/19 绿。
- 全量 desktop replay 套件：503/503 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿
  （无签名 profile 的 WARN 为既有预期）。
- ArkTS 静态检查随构建通过，无新增错误。

## 提交

`Phase 613: text-edit commits carry vnf.d coalesce tracks (INSERT/REMOVE_TEXT)`
