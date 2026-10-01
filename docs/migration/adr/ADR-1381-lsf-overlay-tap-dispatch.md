# ADR-1381: lsf 点选型单元素选区的界内命中分发（zf3 case1）

## 状态

已接受（2026-08，Phase 1446）

## 背景

Phase 603 曾按 1.0.3 `dl1` 证据建立 `insideOverlayElementTap`：单文本块选区命中同块 → 链接探/进编辑；纯组命中非文本成员 → 消费。1.4.2 `zf3` case1 全解码后暴露两处偏差：

1. **lsf 支无界内拖拽域**——`zf3` 对 `lsf`（点选型单元素）直接 `dtfVar.a(jE,null)` 命中分发：界内落空 → `xsf`→`rv0` 清选；界内命中异元素 → `btf`→`ch1` case8 重选并 `e.c` 起移动会话；同元素 vvh → `zsf` 进编辑；同元素非 vvh → `ctf` 拖拽。Harmony 此前界内非自身命中/落空一律拖拽旧选区。
2. **`zsf` 不入 `isf`**——`isf`（含套索圈中的单文本块）界内点按一律 `ctf` 拖拽；Harmony 旧 `singleText` 门不区分来源，套索单文本界内点按误进编辑。
3. **`ch1` case8 尾部 `dtfVar.e.c(tap, msf)` 无条件起移动会话**——选区外命中换选后同一手势可拖新选区；Harmony 两处选区外重选点缺 `beginSelectionDragSession`（仅无选区路径 3819 有）。

## 决策

1. `insideOverlayElementTap` 重构为 `lsfLike`（`!supportsDeselectMode && groupIds==0 && 总数==1`，复用 P1439 来源标记）+ ksf 两支，签名增 `screenP`：
   - lsfLike 界内落空 → `clearSelectionWithRegisterReset()`（xsf→rv0）。
   - lsfLike 界内异命中 → `applyTapSelect`（组命中选组，rsf→jsf 等价）+ `beginSelectionDragSession`（e.c 等价）。
   - lsfLike 同文本块 → 链接探/`beginTextEditingAt`（zsf→case9，`caretIndexAtPoint` = `w8d.d` 等价）。
   - lsfLike 同非文本 → `false` → 拖拽（ctf）。
   - 非 lsfLike（isf/jsf/多元素）→ 保持界内拖拽域语义；isf 单文本界内点按不再进编辑。
2. 两处选区外命中重选点（DEFAULT 面 ~3705、SELECTION 面 ~3836）补 `beginSelectionDragSession`（case8 `e.c` 同手势移动会话；slop 门不变）。
3. `jsf` 非 vvh 组成员命中消费语义保持（原版 `zsf`→`zyh(非文本)` 为文本控制器 no-op）。
4. 编辑会话激活压制（`z2 && r3e.F≠null → atf`、vsf 早退）由既有 `textEditing` 先行门覆盖，不重复移植。

## 后果

- 点选单文本块再点同块进编辑的表层行为不变；套索圈选单文本块后界内点按改为拖拽（原版语义）。
- 点选单元素选区界内压中重叠元素时重选新元素并可同手势拖动；界内落空（如斜笔画选区角部空隙）清选而非误拖。
- 选区外命中换选后可直接同手势拖动新选区（此前需抬手再按）。

## 验证

`d02-original-lsf-overlay-tap.mjs` 13/13；`d02-original-selected-element-tap.mjs` 15/15（更新签名与 lsf 断言）；`d02-original-text-surface-selection-dispatch.mjs` 15/15；`d02-original-tap-caret-place.mjs` 12/12。
