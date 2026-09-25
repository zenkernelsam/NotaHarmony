# ADR-0688：原版导入确认按钮上下文文案对齐

- 状态：已接受
- 日期：2026-09-25
- 关联：`docs/migration/evidence/original-import-confirm-label-jadx-2026-09-25.md`、
  `docs/migration/replays/d02-original-import-confirm-label.mjs`、
  `docs/migration/reports/phase-740-original-import-confirm-label.md`

## 背景

`ImportDetailsSheet.ets` 的确认按钮原为静态 `"Import"`/`"导入"`。
原版 `y5j.a` 的确认钮随目的地状态变化：选中现有笔记 →
`add_to_note`（"Add to \"%1$s\""，空题回退 `default_note_title`）；
多文件合并 → `create_single_note`；单文件/各自 → `create_new_note`。

## 决策

1. `confirmLabel()` 按目的地返回上下文 Resource：
   - `EXISTING_NOTE` → `import_add_to_note`（"Add to \"%s\""），
     目标题空时经 `getStringSync(untitled_note)` 兜底（等价
     `y5j.java:59` 的 null||empty→`default_note_title`）；
   - `SINGLE_NOTE` → `import_create_single`（"Create single note"）；
   - `SEPARATE_NOTES` → `import_create_new`（"Create new note"）。
2. 结构差异保持不移植：原版为"双动作钮"（[Add to existing]+
   [Create …]），Harmony 为"三目的地 chip + 单确认钮"（多出的
   `SINGLE_NOTE` 合并为既有增强）——仅对齐确认文案，不改编排。
3. 原版未选笔记态的 `Add to existing note`/`Loading…` 文案在
   Harmony 由 `importEnabled()` 门禁等价覆盖（钮禁用而非换文案），
   记为已记录偏差。
4. `import_confirm` 资源键保留（d05 fixture 钉其存在）。

## 影响

- `ImportDetailsSheet.ets`：`common` kit 导入 + `confirmLabel()` +
  确认钮绑定。
- `string.json`（base/zh_CN）：新增 `import_add_to_note`、
  `import_create_single`、`import_create_new`。
- 可见差异：确认钮按目的地显示 "Add to \"<题>\" / Create single
  note / Create new note"（zh: 添加到“<题>”/创建单个笔记/创建新笔记），
  替代静态 "Import"。
