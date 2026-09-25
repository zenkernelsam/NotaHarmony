# Phase 740 — 原版导入详情页确认钮上下文文案对齐

- 日期：2026-09-25
- 类型：UI 文案缺口修复（上下文确认钮）
- ADR：ADR-0688
- 证据：`docs/migration/evidence/original-import-confirm-label-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-import-confirm-label.mjs`

## 背景

Phase 739 追 `y5j`（导入编排"Add to note"行）时发现原版确认钮
为上下文文案，Harmony 侧为静态 "Import"。

## 原版证据

`y5j.java:59-77`：确认钮 `strD`/`strD2` 随状态变化——
选中现有笔记 → `add_to_note`（"Add to \"%1$s\""，目标题
null||empty → `default_note_title`）；多文件 → `create_single_note`
（"Create single note"）；单文件/未选 → `create_new_note`；
未选现有笔记态 → `add_to_existing_note`/`loading`。

## 变更

- `ImportDetailsSheet.ets`：新增 `confirmLabel()`，确认钮
  `Button($r('app.string.import_confirm'))` →
  `Button(this.confirmLabel())`；EXISTING→`import_add_to_note`
  （空题经 `untitled_note` 兜底）、SINGLE→`import_create_single`、
  SEPARATE→`import_create_new`；新增 `common` kit 导入。
- `string.json`（base/zh_CN）：`import_add_to_note` /
  `import_create_single` / `import_create_new` 三键；
  `import_confirm` 保留（d05 钉存在）。

## 验证

- 聚焦 Replay `d02-original-import-confirm-label`：30 断言全绿。
- 全量 Desktop Replay：8999/8999 全绿。
- ArkTS 构建 + clean + `note@ohosTest` + `note@default` 双 HAP
  成功（仅存量告警）。

## 偏差与遗留

- 原版"未选态"文案（`Add to existing note`/`Loading…`）在 Harmony
  由 `importEnabled()` 钮禁用等价覆盖（ADR-0688 §3）。
- 原版双动作钮结构 vs Harmony chip+单钮结构：仅对齐文案，
  不改编排（Harmony SINGLE_NOTE 合并为既有增强）。
- 模拟器/真机/Hypium 未执行（按规则）。
