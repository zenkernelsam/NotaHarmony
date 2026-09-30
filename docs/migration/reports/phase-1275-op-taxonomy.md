# Phase 1275 报告 — CRDT 操作分类法

## 完成内容

- `haa` = 32-op CRDT 枚举 —— 协同文本（INSERT_CHAR/
  STRING, REMOVE_CHAR(S), **REVIVE_CHARS** 墓碑复活）、
  样式（MODIFY_STYLE/PARAGRAPH/CLEAR）、墨迹（CREATE/
  ADD_PATH_ELEMENTS/MODIFY_INK）、图形/分组/块、
  DELETE_ENTITIES、PDF_FIELD、CHECKBOX、COMMENT、
  PEER_INTERACTION；`tmf`=long Lamport 时间戳；
  `sdf`=实体表（qo5+mmf）—— 完整协同文档模型。

## 产出

- evidence `phase-1275-op-taxonomy.md`
- fixture `d02-op-taxonomy.mjs`（10/10）
- ADR-1219
