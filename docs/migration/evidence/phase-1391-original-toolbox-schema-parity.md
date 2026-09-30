# Phase 1391 证据 — Toolbox 升级回填托盘定位 + `tool_state` 列补齐

> 源码证据：`decompiled_1.4.2`（1.4.2 APK，v1040002）。本 Phase 解决两处
> **1.4.2 迁移缺陷**：① 升级回填把缺失工具放到「Primary 计数」索引而非
> 所属托盘尾部；② `tool_state` 缺 `ToolStateEntity` 两列。

## 1. SHAPE 升级回填托盘定位（gb7.java:107）

原版升级 SQL `gb7.java:107` —— SHAPE 工具回填：

```sql
INSERT INTO ToolStateEntity(...,tray_owner_id,trayIndex,...)
SELECT ...,tray.tray_id, (SELECT MAX(sibling.trayIndex)+1
       FROM ToolStateEntity sibling
       WHERE sibling.tray_owner_id=tray.tray_id), ...
FROM TrayEntity tray WHERE tray.tray_type='Secondary' AND NOT EXISTS(...)
```

- 目标托盘 = **`tray_type='Secondary'`**（SHAPE 属副托盘）。
- `trayIndex` = 该托盘内 `MAX(sibling.trayIndex)+1`（`sibling.tray_owner_id`
  限定同托盘）——追加到**副托盘尾部**。

**Harmony 旧缺陷**（`EditorViewModel` 回填）：`backfill.trayIndex =
primaryCount` —— 用 **Primary 工具计数**当索引，却保留种子 `trayType=SECONDARY`。
升级用户的 SHAPE 落到 Secondary 上一个由 Primary 数算出的索引（空位错置）。

**修正**：`nextTrayTailIndex(merged, backfill.trayType)` 返回该托盘
`MAX(trayIndex)+1`，`backfill.trayIndex` 用之——与原版同托盘尾部追加一致。

## 2. `tool_state` 列补齐（ca3.java:555 → ToolStateEntity 18 列）

原版 `ToolStateEntity` DDL（`ca3.java:555`）逐列比对，Harmony 缺两列：

| # | ToolStateEntity 列 | Harmony 旧态 | 本 Phase |
|---|--------------------|--------------|----------|
| 5 | `googleInkBrushPackId` INTEGER | 缺 | `google_ink_brush_pack_id` |
| 10 | `penLastStandardColorWellIndex` INTEGER | 缺 | `pen_last_standard_color_well_index` |

- **`penLastStandardColorWellIndex`**（`zsi.n`，持久化）：pen 记忆其最后一个
  **标准**色井索引。原版写侧在标准色井选择时记录；选自定义/最近色时
  `selectedColorWellIndex=-1` 而本字段保留。**写侧**：`setBrushColor` 当
  `selectedWellIndex>=0` 记为 `penLastStandardColorWellIndex`。
- **`googleInkBrushPackId`**：Google Ink 笔刷包 id —— Harmony 无该私有引擎，
  保持 `NULL`（schema/round-trip 保留，fail-closed，非实现）。

DB_VERSION `72→73`，migration 73 执行两列 `ALTER TABLE tool_state ADD COLUMN`。

## 3. 相关原版迁移佐证

`zmb.java:118` —— `style` INTEGER→TEXT 迁移映射 `0→'Mono',1→'Taper',
2→'Dash',3→'Dot'`（即 `o81` 枚举名）；`ca3.java:405` `ToolStateEntity`
字段序确认 `penLastStandardColorWellIndex`（字段 `n`）与
`googleInkBrushPackId` 均 `INTEGER DEFAULT NULL`。

## 4. Harmony 实现映射

| 原版 | Harmony |
|------|---------|
| `gb7:107` MAX(sibling.trayIndex)+1 同托盘 | `nextTrayTailIndex(merged,trayType)` |
| `ToolStateEntity.penLastStandardColorWellIndex` | `tool_state.pen_last_standard_color_well_index` + `setBrushColor` 写侧 |
| `ToolStateEntity.googleInkBrushPackId` | `tool_state.google_ink_brush_pack_id`（恒 NULL，fail-closed） |
| `zsi.n` 持久化字段 | `rowToState`/`toBucket`/`cloneState`/`createState` 全链路透传 |

## 5. 回归

`docs/migration/replays/d02-original-toolbox-schema-parity.mjs`（17 检查）+
全量 `REPLAY_BASELINE`。版本钉线 fixtures（8 处 `DB_VERSION=72`）随升 73 同步
更新 `note/src/test/DatabaseHelper.test.ets` `assertEqual(73)`。
