# ADR-1118：data/ Room 总账（10 DB）→ RDB

## 状态

已接受（Phase 1174）。

## 决策

命名 `data/` 包共 **10 个 Room `x5c` DB**（note assets/
metadata/state、library、learn、search index/result、
settings、toolbox、transcription）—— 全部 → Harmony
**RDB**（`relationalStore`）；拆库语义保留（10 域）。

## 理由

`abstract X extends x5c` + `X_Impl` ×10 —— Room 单域
拆库模式。

## 后果

Harmony 持久化 = 10 RDB 域（或一库多表分域）；
Room API→RDB 适配层；迁移路径 Room→RDB 为独立项。
