# Phase 593 — 覆盖层内元素级 ttc 产出（itc/gtc 分支）

- 日期：2026-09-28
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-selected-element-tap-2026-09-28.md`
- ADR：`docs/migration/adr/ADR-0562-original-selected-element-tap.md`
- Replay：`docs/migration/replays/d02-original-selected-element-tap.mjs`（10 项断言）

## 背景

Phase 592 后补 `dl1` 剩余分支审计：原版选区覆盖层内按下按 `htc`
子类型（`itc` 单元素/`ftc` 多元素/`gtc` 组）分流——并非一律拖拽：

- `itc`：命中同一 `xhe`（`cie` 文本块实体）→ `ttc` → `qke`
  （`uke` 激活文本块编辑器）+ `rej.i` 链接探测。
- `gtc`：命中 `gtc.b` 内非文本成员 → `ttc` → `qke` 非文本 no-op
  （消费不拖拽）；文本成员/非成员 → `wtc` 拖整组。
- `ftc`：恒 `wtc`。

Harmony 此前覆盖层内按下恒 `selectionDrag`，两处偏差：
单文本块选区无法单击激活编辑；组内成员点按误拖整组。

## 实现

`NoteCanvasView` 覆盖层内按下分支前置元素级分流：

1. `singleText`（仅一个 `selectedTextBlockIds`）且命中同块 →
   `linkHitOnTextBlock` → 链接菜单 / `beginTextEditingAt`。
2. `selectedGroupIds` 非空且命中非文本成员，且选区为纯组选区
   （`resolveOriginalSelectedGroupLeaves` 叶子集 == 选中实体集）→
   消费不拖拽。
3. 其余 → 既有整体拖拽。

新增 `selectedEntityIdSet(state)` 成员集助手。

## 偏差

见 ADR-0562 §偏差：链接探测先于激活（顺序近似）；`ufb.I`/`z2`
门控无对应层；混合选区按 `ftc` 恒拖拽。

## 验证

- `node docs/migration/replays/d02-original-selected-element-tap.mjs` → 10/10。
- `d02-original-selection-tap-clear.mjs` 窗口随代码增长放宽。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
