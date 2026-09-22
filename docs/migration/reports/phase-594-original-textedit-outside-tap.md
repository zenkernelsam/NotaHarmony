# Phase 594 — 文本编辑中块外点按 → 提交并停用（oke.a）

- 日期：2026-09-28
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-textedit-outside-tap-2026-09-28.md`
- ADR：`docs/migration/adr/ADR-0563-original-textedit-outside-tap.md`
- Replay：`docs/migration/replays/d02-original-textedit-outside-tap.mjs`（6 项断言）

## 背景

原版 TEXT 工具点按面（`ha5`/`zl2` case25）：编辑中点按命中块 →
`qke` 激活；块内 → 保持；块外 → `oke.a` 提交并停用，且该次点按
只驱动编辑器状态、不产生笔迹。

Harmony `TextBlockOverlay` 零尺寸不拦截触摸——编辑中画布点按
照常走工具分发而编辑器保持打开，存在"边画边编辑"的迁移缺陷。

## 实现

`onTouchDown` 头部（`clipboardPasteTarget` 后、工具分发前）：
`textEditing` 中——块内点按直接 `return`（TextArea 自理）；块外
点按 `onTextCommit(editingDraftText)`（尾部停用编辑器）并消费。

## 偏差

见 ADR-0563 §偏差：切换激活需两次点按；停用对所有工具生效；
提交异步且 busy 守卫下可被拒绝。

## 验证

- `node docs/migration/replays/d02-original-textedit-outside-tap.mjs` → 6/6。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
