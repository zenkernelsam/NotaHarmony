# ADR-1276：协作文本 op（墓碑）

## 状态

已接受（Phase 1333）。

## 决策

协作文本 = 逐字符 CRDT 身份 + `visible` 墓碑 +
预测插入身份 —— 对照 `haa` INSERT/REMOVE/REVIVE_CHARS。

## 理由

`OriginalLocalTextMutation`：`StoredCharacter{identity,
visible}` —— remove 置 `visible=false`（墓碑不物理删）、
revive 置回 `true`、insert 用 `predictOriginalTextInsertion
Identity(ts,siteId)` 生成 CRDT 身份；`previewMutation`
模拟→计划。对照 `haa` 文本 op（墓碑支持并发+复活）。

## 后果

协作文本支持墓碑化删除+复活 —— CRDT 并发编辑保真。
