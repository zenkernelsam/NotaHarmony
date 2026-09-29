# ADR-1021：v69 实体表名册 + 全知检查

## 状态

已接受（Phase 1077）。

## 决策

Harmony 文档根持六张因果集合表（`uia`/`aja×2`/`bja×2`/`qja`），
op-apply 前置 `ba6.j` 全实体已知检查（含 `r().I` tombstone）。

## 依据

`ba6.j` 遍历五表+条件 r；`xhe` 墨实体 iface。

## 后果

Harmony：apply 前先 resolve 全部实体 id——缺则遥测错误，
不写半状态。
