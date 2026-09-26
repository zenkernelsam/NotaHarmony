# Phase 799 证据：文档-代码一致性清扫（fixture 引用面）

日期：2026-09-29
性质：一致性修正 + 登记（不改 Harmony 功能源码）。
证据源：`docs/migration/{adr,evidence,replays,reports}` 全量
交叉引用扫描。

## 1. 发现与修正

**(a) 失效软引用 + 空断言** —
`d02-original-feature-note-tail.mjs` 读
`ADR-0513-original-collaboration-boundary.md`（该文件从未
存在），且断言 `adr0513.length > 0 || true` 恒真（vacuous）。
修正：改读 `ADR-0658-original-remote-flag-tail-failclosed.md`
（协作面 fail-closed 登记 ADR），断言改为
`includes('协作')` 实质检查。

**(b) 陈旧交叉引用** — ADR-0670 两处引 "ADR-0513" 为协作
后端边界；实际 0513 是笔记上下文菜单 ADR（Phase 541）。
修正为 ADR-0658（协作面 fail-closed）。

**(c) 孤儿 fixture** — 9 个 replay 无任何文档引用，均源自
`fix(...)`/`feat(...)` 直通提交（绕过 Phase 流程）：

| fixture | 起源提交 |
|---------|---------|
| d02-asset-reference-migration-cleanup | 73806944 fix(settings) |
| d02-history-checkpoint | 2f645899 fix(D-02) |
| d02-note-delete-existence-rollback | ee865033 Phase 531 / bcaeb63f fix(library) |
| d02-original-image-render-orientation | ec618b93 fix(image) |
| d02-original-shape-partial-eraser | 60031881 fix(eraser) |
| d02-recording-completion-advance-count-bound | 225da639 fix(page) |
| d02-recording-playback-controller | 1a0dcfac feat(recording) |
| d02-system-backup-relative-path-segments | 5016d5e7 fix(backup) |
| d02-webdav-href-resource-identity | 4759bedc fix(webdav) |

处置：入册为"独立回归 fixture"（见修复进展登记段），
后续 Phase 仍须按流程挂接文档。

## 2. 已绿项

- 156 个 `note/src/**` 代码锚点全部存在（0 断链）。
- fixture 内 `docs/migration/**` 引用仅剩上述一处失效
  （已修）。
- 全部 671 fixture 引用面登记完成。

## 3. 防回归

`d02-consistency-fixture-references.mjs` 钉住：
无 `|| true` 空断言、fixture 均被文档引用或列入独立
登记段、ADR-0670 不再引 ADR-0513。
