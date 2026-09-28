# Phase 964 报告 — zq9 写侧全貌

## 范围

zq9.java 全部静态成员。纯审计。

## 原版发现

- `a` = 30 项 KClass→haa 逆映射（ee8=MODIFY_PDF_FIELD 订正）。
- `e` = 7 字段信封写器 + z(4)/z(14) 双 required（id+payload），
  与 Phase 905 读侧逐槽镜像。
- `d`/`a`/`c` = 入口/工厂/读分派别名。

## 产出

- 证据：`phase-964-zq9-envelope-writer.md`
- Fixture：`d02-zq9-envelope-writer.mjs`（47/47）
- ADR-0908；全量 Replay 837 文件绿。
