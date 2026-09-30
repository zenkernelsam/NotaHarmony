# Phase 1391 报告 — Toolbox 升级回填托盘定位 + `tool_state` 列补齐

- 阶段：1391
- ADR：ADR-1327
- 证据：`docs/migration/evidence/phase-1391-original-toolbox-schema-parity.md`
- Replay：`docs/migration/replays/d02-original-toolbox-schema-parity.mjs`（17 检查）

## 背景

对照 `decompiled_1.4.2` 的 `ca3.java`（`ToolStateEntity` 完整 DDL）与
`gb7.java`（SHAPE 升级回填 SQL），审计 toolbox/`tool_state` 数据层，
发现两处迁移缺陷。

## 缺陷 1 — SHAPE 升级回填托盘错位

原版 `gb7.java:107`：SHAPE 回填进 `tray_type='Secondary'` 托盘，
`trayIndex = MAX(sibling.trayIndex)+1`（同托盘限定）。

Harmony 旧代码 `backfill.trayIndex = primaryCount`：用 **Primary 工具计数**
当索引，但种子 `trayType=SECONDARY` 保留——SHAPE 落到 Secondary 上一个
Primary 派生的错位索引。且 Secondary 索引非稠密（1/2/3/5，POINTER@0、
RULER@4 留空），count 与 MAX 语义皆错。

**修复**：`nextTrayTailIndex(merged, trayType)` 返回该托盘 `MAX+1`，
`backfill.trayIndex` 用之。

## 缺陷 2 — `tool_state` 缺两列

对照 `ToolStateEntity`（ca3.java:555，18 列），Harmony 缺：

| 列 | 原版 | 本 Phase |
|----|------|----------|
| `pen_last_standard_color_well_index` | `zsi.n`，pen 记忆最后标准色井 | 新增 + `setBrushColor` 写侧 |
| `google_ink_brush_pack_id` | Google Ink 笔刷包 id | 新增（恒 NULL，fail-closed） |

DB_VERSION `72→73`，migration 73 加两列 `ALTER TABLE tool_state ADD COLUMN`。
`ToolState`/`rowToState`/`toBucket`/`cloneState`/`createState` 全链路透传。

## 改动文件

- `note/src/main/ets/core/model/BrushTypes.ets` — `ToolState` 增两字段
- `note/src/main/ets/data/DatabaseHelper.ets` — DB_VERSION=73、DDL、migration 73
- `note/src/main/ets/data/ToolRepositoryImpl.ets` — rowToState/toBucket/cloneState
- `note/src/main/ets/ui/editor/EditorViewModel.ets` — nextTrayTailIndex、
  backfill 修正、createState/cloneState、setBrushColor 写侧
- `note/src/test/DatabaseHelper.test.ets` — `assertEqual(73)`
- `docs/migration/replays/d02-original-toolbox-schema-parity.mjs`（新增）
- 8 处版本钉线 fixtures `DB_VERSION=72→73`

## 验收

- 硬证据：`ca3.java:555`（DDL）、`gb7.java:107`（回填）、`zmb.java:118`、
  `zsi.java`/`svi.java`（字段序）。
- `d02-original-toolbox-schema-parity` 17 检查绿；全量 `REPLAY_BASELINE` 全绿。
- `note@ohosTest`、`note@default` HAP 构建成功，无新增 ArkTS 错误。

## fail-closed

`googleInkBrushPackId` 恒 `NULL`——Google Ink 私有引擎不实现，仅保留列供
schema/round-trip。`penLastStandardColorWellIndex` 读侧恢复语义待原版
混淆代码进一步取证后另立 Phase；本 Phase 仅落 schema + 写侧。
