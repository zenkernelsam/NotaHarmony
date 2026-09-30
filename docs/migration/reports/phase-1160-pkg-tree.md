# Phase 1160 报告 — 全包树（milestone）

## 完成内容

- `com.gingerlabs.notability` 完整命名包树盘点：
  `app`/`core`(CRDT+FB+glmath+network)/`data`(12 仓储)/
  `domain`/`feature`(login+toolbox-audio)/`ui`。
- 迁移边界：data→relationalStore；login/billing→
  OAuth/支付 fail-closed；stylus/transcription 适配。

## 产出

- evidence `phase-1160-pkg-tree.md`
- fixture `d02-pkg-tree.mjs`（10/10）
- ADR-1104
