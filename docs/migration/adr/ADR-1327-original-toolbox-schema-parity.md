# ADR-1327 — Toolbox 升级回填托盘定位修正 + `tool_state` 列补齐

- 状态：已接受
- 日期：2026-08（Phase 1391）
- 证据：`docs/migration/evidence/phase-1391-original-toolbox-schema-parity.md`

## 决策

修正两处 `toolbox`/`tool_state` 数据层迁移缺陷：

1. **缺失工具回填 → 所属托盘尾部**。原版 `gb7.java:107` 升级 SQL 把 SHAPE
   插入每个 owner 的 `tray_type='Secondary'` 托盘，`trayIndex =
   MAX(sibling.trayIndex)+1`（`sibling.tray_owner_id` 限定同托盘）。
   Harmony 旧实现 `backfill.trayIndex = primaryCount` 用 **Primary 计数**
   当索引，却保留 `trayType=SECONDARY`——升级用户的 SHAPE 落到 Secondary
   上一个 Primary 派生的错位索引。改以 `nextTrayTailIndex(merged, trayType)`
   返回该托盘 `MAX+1`，与原版同托盘尾部追加一致（Secondary 种子索引
   1/2/3/5 含 POINTER@0/RULER@4 空位，非稠密——必须用 MAX 而非 count）。

2. **`tool_state` 列补齐**（`ca3.java:555` `ToolStateEntity` 18 列比对）。
   补两列 + migration 73（DB_VERSION 72→73）：
   - `pen_last_standard_color_well_index`（原版 `zsi.n`，持久化）：pen 记忆
     最后**标准**色井索引。`setBrushColor` 当 `selectedWellIndex>=0` 写回；
     自定义/最近色选 `selectedColorWellIndex=-1` 时本字段保留。
   - `google_ink_brush_pack_id`（原版 `ToolStateEntity` 字段5）：Google Ink
     笔刷包 id。**fail-closed**：Harmony 无 Google Ink 私有引擎，列保留
     schema/round-trip 但恒 `NULL`，不实现引擎行为。

   全链路透传：`ToolState` 接口 + `rowToState`（null 容忍）+ `toBucket` +
   `cloneState`（repo/VM）+ `createState`（默认 null）。

## 显式差异

- `penLastStandardColorWellIndex` 的**读侧消费**（pen 重选时恢复标准色）在
  原版被混淆压缩，无法逐位取证——本 Phase 只补齐 schema + 写侧（标准井选择
  记录），读侧恢复语义未新增猜测性行为。读侧若后续取证到再补。
- `googleInkBrushPackId` 恒 NULL：Google Ink 引擎 fail-closed，仅保留列。

## 回归

`d02-original-toolbox-schema-parity.mjs`（17 检查）；版本钉线 fixtures
（8 处 `DB_VERSION=72`）随升 73 同步 `DatabaseHelper.test.ets` `assertEqual(73)`。
全量 `REPLAY_BASELINE` 全绿。
