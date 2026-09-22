# ADR-0563 — 文本编辑中块外点按 → 提交并停用（oke.a）

- 状态：Accepted
- Phase 594；对齐 `zl2` case25/`uke` oke.a/`ha5`/`e5j`（decompiled_1.0.3）。

## 背景

原版 TEXT 工具点按面（`ha5`→`zl2` case25）：编辑中点按
- 命中另一文本块 → `qke(id)` 切换激活；
- 落在当前编辑块内 → 保持编辑；
- 块外 → `oke.a` 提交并停用编辑器，且该次点按只驱动编辑器状态、
  不落到笔迹/选区分发。

Harmony `TextBlockOverlay` 零尺寸不拦截画布触摸——编辑中画布点按
照常走工具分发而编辑器保持打开，出现"边画边编辑"状态。

## 决策

`onTouchDown` 头部、所有工具分发之前：
- 块内点按 → `return`（TextArea 自理）。
- 块外点按 → `onTextCommit(editingDraftText)`（其尾部置
  `textEditing=false; editingTextBlock=null`）并消费该次点按——
  对齐"点按只驱动编辑器"语义：第一次点按退出编辑，下一次点按才
  按当前工具正常分发。

## 偏差（fail-closed 记录）

1. 原版块外命中另一文本块直接切换激活；Harmony 先停用再由后续
   点按重新进入——多一次点按。
2. 块外停用对所有工具生效（原版 TEXT 面全局挂接，语义等价）。
3. 提交为异步；busy 守卫下被拒绝时编辑保持——并发保护等价。

## 验证

- `docs/migration/replays/d02-original-textedit-outside-tap.mjs` 6 项断言。
- 证据：`docs/migration/evidence/original-textedit-outside-tap-2026-09-28.md`。
