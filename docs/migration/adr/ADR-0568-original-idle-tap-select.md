# ADR-0568 — 无选区时点按元素直接选中（dl1 case2 末支 → vtc）

- 状态：Accepted
- Phase 599；对齐 `dl1` case2/`uw2` case3（decompiled_1.0.3）。

## 背景

原版 `xtc` 按下分发末支：无选区（`ktcVar==null`）且按下命中
页面元素 → `vtc` TapToSelect——按下即产生 `itc`/`gtc` 选区
（`uw2` case3：组→`gtc`、单元素→`fvb.d(id)`），同一手势随后
按 `wtc`/`e39` 拖动；未命中 → `utc` 返回 null，手势落空交给
工具（套索/绘制）。这是 POINTER 工具的核心语义，也经
`rz1.C` 挂到 ink 工具表面。

Harmony `SELECTION` 工具合并了原版 SELECT（套索）+ POINTER
（点选拖动），但空选区按下一律 `beginSelection`——点按元素
只能套索（且 Phase 598 后点按微区域会被最小尺寸门取消），
无法直接点选对象。

## 决策

`selectionVisible=false` 分支、文本链接命中检查之后：

1. `topmostPageElementIdAt(canvasP)` 命中 →
   `resolveOriginalGroupSelection`（cqc 组解析，`ntc`→`gtc`
   等价）+ `selectElementIds` 提交 + `updateSelectionOverlay`
   + `renderFrame`。
2. 同手势置 `selectionDrag=true` + `dragBefore*` 快照 +
   `lastDragPoint`——点住即拖（`uw2` case3 → `wtc`/`e39`
   等价）；纯点按（identity transform）不产生 undo（既有
   `isIdentityTransform` 门）。
3. 未命中 → 原套索/矩形 `beginSelection`（`utc` 落空等价）。
4. 文本块链接命中仍先于点选（`ttc`→`qke` 语义优先）。

## 偏差（fail-closed 记录）

1. 原版按表面区分指针类型：TEXT 面 `z=true` → 仅手指/侧键
   点选；ink 面 `z=false` → 任意指针。Harmony SELECTION 为
   合并工具，统一接受全部指针类型点选（POINTER 语义）；
   文本工具表面无 `xtc` 挂接差异——Harmony 无独立 TEXT 面。
2. 原版 `vtc` 分发带 `pke.a` 反馈事件（触觉/音效通道）；
   Harmony 无对应反馈层，语义为无反馈点选。
3. 原版 POINTER 面点选由 `j74`/`gfe.f` 轻拍检测产出（up 时
   确认）；`rz1.C` 面为 down 即时。Harmony 取 down 即时语义，
   与既有 outside-press TapToSelect 一致。

## 验证

- `docs/migration/replays/d02-original-idle-tap-select.mjs`
  14 项断言（命中优先/组解析/同手势拖动/落空套索 + 三态模型）。
- 证据：`docs/migration/evidence/original-idle-tap-select-2026-09-23.md`。
