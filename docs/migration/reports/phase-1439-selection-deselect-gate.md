# Phase 1439 — 选区种类门控：DESELECT 仅 isf 型选区装配

## 原版硬证据（decompiled_1.4.2）

- `wqf` 元素选择菜单枚举共 23 项；`urf` 装配器按 `msf` 选区类型条件
  装配，**DESELECT 仅 `isf` 出现**。
- `msf` 四实现：`isf`=绘制完成/集合程序化选区；`lsf`=单元素点选
  （`ch1.java:155`、`hmb.i(t87)`）；`jsf`=组点选（`ch1.java:178`、
  `j01:87`）；`hsf`=进行中套索（`j01:75` warn），完成经 `z6c` 转 `isf`。
- `j01.java:59-90` 穷尽分支：粘贴到既有选区按原种类保种
  （isf→isf / lsf→`new lsf` / jsf→`new jsf` / hsf→拒绝）；无既有
  选区时粘贴集合经 `mud` set-select 产 `isf`。
- `tsf` 仅 `rsf`(组)/`ssf`(单元素) 两实现——点选分发永不产 `isf`。

## Harmony 缺口与实现

此前 `SelectionState` 无来源标记，`SelectionOverlay` 的 DESELECT 行
无条件装配——点选单元素/组也显示该行，与原版不符（`dhb` case20 的
deselectMode 本体即 isf 专属能力）。

实现（`SelectionTool.ets`/`NoteCanvasView.ets`/`SelectionOverlay.ets`）：

- `supportsDeselectMode` 种类标记（非基数——单元素集合与单元素点选
  基数相同但种类不同）；`beginSelection`/`deselect`/空调入复位；
  `finalizeSelection` 命中非空→`true`（hsf→isf 等价）。
- `selectElementIds` 加 `drawnKind?: boolean` 三态：`false`=lsf/jsf
  点选型，`true`=isf 集合型，`undefined`=保种（j01 语义）。
- `enterDeselectMode` 加 `supportsDeselectMode` 同判兜底。
- 调用点分类：`applyTapSelect`→false；select-all/全选删除→true；
  两处粘贴→`selectionVisible ? undefined : true`；图片插入→
  `selectionVisible ? undefined : finalImages.length > 1`；数学插入→
  `selectionVisible ? undefined : false`；裁剪重断言、变换重断言
  省略参数（保种）。
- Overlay：`@Prop canDeselect` 门控 DESELECT 行；`selectionCanDeselect`
  @State 镜像于 `updateSelectionOverlay`。

## 有意差异登记

- 单图片插入按 `hmb.i`→lsf 类推隐藏 DESELECT；多图按 `mud`→isf 显示。
  `ty9` 插入路径 select 实现为 suspend 方法引用未完全展开——保守方向
  近似，已在 ADR-1374 登记。

## 验证

- 目标 fixture `d02-selection-deselect-isf-gate.mjs`：18/18 green
  （字段/复位/置真/三态/兜底/调用点分类/门控/镜像/文档闭环）。
- 全量 Desktop Replay 基线：见下方验收段。
- `note@default` / `note@ohosTest` 构建：见下方验收段。

## 关联文档

- 证据：`docs/migration/evidence/phase-1439-selection-deselect-gate.md`
- ADR：`docs/migration/adr/ADR-1374-selection-deselect-gate.md`
- 菜单枚举其余装配差异：ADR-0645 全表登记。
