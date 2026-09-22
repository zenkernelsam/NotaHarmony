# Phase 612 — deselectMode 点按命中测试白名单（xtc.a(jE, ftc.g)）

- 日期：2026-09-23
- 结果：已实现对齐
- 证据：`docs/migration/evidence/original-deselect-hit-whitelist-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0581-original-deselect-hit-whitelist.md`
- Replay：`d02-original-deselect-hit-whitelist.mjs`（13 项断言）

## 背景

原版 deselectMode 按下：`xtc.a(jE, ftc.g)`——`fu1.e` `set` 参
把命中测试白名单限定在选中 id 集，精确与 ±5 容差两程同适用。
未选中元素不遮挡下层被选中元素——点按穿透命中 → `stc` 移除。

Harmony 旧实现 `deselectTargetIdsAt` 先取全集最上层命中再判
`selected.has`——顶层未选中元素挡住下层被选中元素，点按落空
（按 utc 抑制或 qtc 退出模式处理）。

## 实现

- `hitOrderedElementIdAt`/`topmostPageElementIdAt` 增可选
  `whitelist` 参——z 序扫描 `!whitelist.has → continue`，
  两程共用（`fu1.e` set 参等价）。
- `deselectTargetIdsAt` 先建 `selected` 扁平集再传入命中。
- 其余调用点默认 `null` 不过滤。

## 验证

- Replay 新增 13 断言；全量 Desktop Replay 502/502 全绿。
- `note@default`、`note@ohosTest` HAP 构建 0 错误。
- 用例：B（未选中）压在 A（已选）上，deselectMode 点按 →
  A 移出选区（原版语义），不再落空。
