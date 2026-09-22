# ADR-0562 — 覆盖层内元素级 ttc 产出（itc/gtc 分支）

- 状态：Accepted
- Phase 593；对齐 `dl1` itc/gtc 分支/`uw2` case4/`uke`/`qke`/`cie(xhe)`
  （decompiled_1.0.3）。

## 背景

原版选区覆盖层内按下并非一律拖拽整体：

- `itc`（单元素选区）：命中同一选中元素且为 `xhe`（`cie`=文本块
  实体）→ `ttc` → `qke` **激活文本块编辑**；非文本 → `wtc` 拖拽；
  命中其它元素 → `vtc` TapToSelect。
- `gtc`（组选区）：命中 `gtc.b` 内非文本成员 → `ttc` → `qke`
  （非文本 id 查找失败 → 实质 no-op，消费不拖拽）；文本成员或
  非成员 → `wtc` 拖整组。
- `ftc`（多元素选区）：恒 `wtc`。

Harmony 此前覆盖层内按下无条件整体拖拽——单文本块选区无法
单击进入编辑，组内成员点按也错误地拖整组。

## 决策

- 覆盖层内按下先 `topmostPageElementIdAt` 探命中元素：
  1. 单文本块选区 + 命中同块 → `linkHitOnTextBlock`（链接命中→
     [Open, Copy Link] 菜单）否则 `beginTextEditingAt`（`qke` 激活）。
  2. 纯组选区（选中实体 = `resolveOriginalSelectedGroupLeaves`
     叶子集）+ 命中非文本成员 → 消费手势不拖拽。
  3. 其余 → 既有 `selectionDrag` 整体拖拽。
- 新增 `selectedEntityIdSet`（`gtc.b` 成员集等价物）。

## 偏差（fail-closed 记录）

1. `itc` 文本 `ttc` 原版同帧激活编辑+链接探测；Harmony 链接命中
   优先（出菜单不进编辑），未命中才激活——顺序差异、语义近似。
2. `ufb.I`/`z2` 门控无对应层，以链接探测替代。
3. 混合选区（组+散件）归 `ftc` 恒拖拽——Harmony 只对"纯组选区"
   （叶子集==选中集）启用成员 ttc，与原版 `gtc` 状态一致。

## 验证

- `docs/migration/replays/d02-original-selected-element-tap.mjs` 10 项断言。
- 证据：`docs/migration/evidence/original-selected-element-tap-2026-09-28.md`。
