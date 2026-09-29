# Phase 1028 报告 — 导出 bundle（.note）

## 范围

`zk9`/`yk9` 导出生成器 + bundle 结构。纯审计。

## 原版发现

- `zk9.a(note,noteId,str,str,bool,w59)` = 导出入口，
  `t13.K` dispatcher 启 `yk9` coroutine。
- `yk9` 写 `manifest.json` + `noteBundle`(FlatBuffer)
  + `assets/`——.note = zip 容器。
- `pa0`/`cba`/`cp5`/`zjb` 资产包装产 wa0 元数据。

## Harmony 决策

导出格式等价（zip+manifest+FlatBuffer+assets）。

## 产出

- 证据：`phase-1028-export-bundle.md`
- Fixture：`d02-export-bundle.mjs`（10/10）
- ADR-0972；全量 Replay 见本提交。
