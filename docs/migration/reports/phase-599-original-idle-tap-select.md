# Phase 599 — 无选区时点按元素直接选中（dl1 case2 末支 → vtc）

- 日期：2026-09-23
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-idle-tap-select-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0568-original-idle-tap-select.md`
- Replay：`docs/migration/replays/d02-original-idle-tap-select.mjs`（14 项断言）

## 背景

原版 `xtc` 按下分发（`dl1` case2）末支：`ktcVar==null` 且命中
页面元素 → `vtc` TapToSelect，按下即产生 `itc`/`gtc` 选区，
同一手势可立即拖动；未命中 → `utc` 落空交工具。这是 POINTER
工具核心语义（`c5f`/`j74`/`ha5` 挂 `xtc`），并经 `rz1.C` 挂到
ink/TEXT 工具表面（指针类型按 `z3` 门控）。

Harmony `SELECTION`（原版 SELECT+POINTER 合并）空选区按下一律
进套索——无法点选对象；点按元素在 Phase 598 最小尺寸门后
直接被取消，行为空缺。

## 实现

`selectionVisible=false` 分支（链接命中检查之后）：

- `topmostPageElementIdAt` 命中 → `resolveOriginalGroupSelection`
  + `selectElementIds` + `updateSelectionOverlay` + `renderFrame`；
  置 `selectionDrag` + `dragBefore*` 快照 + `lastDragPoint`——
  点住即拖；纯点按 identity transform 不产生 undo。
- 未命中 → 原套索/矩形 `beginSelection`。

## 偏差

见 ADR-0568 §偏差：合并工具统一全指针点选（原版 TEXT 面限
手指/侧键）；无 `pke.a` 反馈层；取 down 即时语义。

## 验证

- `node docs/migration/replays/d02-original-idle-tap-select.mjs` → 14/14。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
