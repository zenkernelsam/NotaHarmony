# ADR-0558：选区拖拽改为元素粒度抓取（stc / ej9 case18）

- 状态：**superseded by ADR-0559**（`ftc.i` 实为 deselectedIds——
  stc/case18 是 deselectMode 点按移除语义，非抓取移动；Phase 590 已纠正）
- Phase：589
- 证据：`docs/migration/evidence/original-selection-granular-grab-2026-09-28.md`

## 背景

Harmony 在 Phase 589 之前：选中态下 pointer-down 落在 `selectionRect`
（选区包围盒）内即 `selectionDrag = true`，`moveSelected`/`applyTransform`
把变换施加到**全部**选中元素——任何选框内按下都拖动整个选区。

原版 `dl1.java` case2（`ftc` 选中态）的分发是**元素粒度**的：

1. `xtc.a(jE, set)` 取该点最上层命中。
2. 命中元素 ∈ 选中集 → `stc({id})`；命中 `cqc` 组且组内任一成员 ∈ 集 →
   `stc(cqc.b, cqc.a)`。
3. `ej9` case18：被抓取 id 从 `ftc.g`（选中集）`ys2.H` 减去、`ys2.J` 并入
   `ftc.i`（moving set）；`nze.java:103` 把 `i` 交给 `aeg` 应用变换——
   **只有被抓取的子集随手指移动**。
4. 未命中元素：覆盖层（`cmb`）内 → `utc` 消费；否则 `qtc → z39(17)` →
   新选区手势。

即"按在选框空白处"在原版里是**开始新选区**，不是拖动整个选区。

## 决定

按原版语义改造 Harmony：

- `SelectionState` 新增 `movingIds`（`ftc.i` 对应物）。
- `hitTestSelectedElementIds`：以 `materializePageElements` 统一 z 序
  逆序（最上层先）做逐类命中——笔画走 `hitStrokeAtPoint` 精确覆盖、
  形状走 `pointHitsShape`、TEXT/IMAGE/MATH 走
  `pointHitsAffineBlock(localBounds, transform)`；命中元素 ∈ 选中集 →
  `expandGrabToSelectedGroup`（命中成员属于被选中 Original 组时抓取整组
  叶子）；命中未选中元素 → null。
- pointer-down 分支：命中 → `grabElements` + 拖拽；未命中 → `beginSelection`
  新选区（`qtc → z39` 等价）；`isInSelectionMenu` 仍先消费菜单区
  （`utc` 等价）。
- `applyTransform`/`applySelectionTransform` 与落点撤销记录统一经
  `movingSubsetOf` 收窄到被抓取子集；松手 `selectElementIds` 重选全集并
  清空 `movingIds`（`g ∪ i` 终态等价：全部保持选中）。

## 有界偏差

1. 抓取期间 `selectionRect` 覆盖层不收缩到未抓取元素上（原版 `ftc` 重建
   后覆盖层口径无静态定论；视觉差极小）。
2. `planSelectionSnap` 吸附锚点仍按整个选区边界计算，未收窄到抓取子集。
3. `cqc` 为原版查询期动态组聚合；Harmony 只展开持久 `selectionGroups`，
   动态"同点覆盖同组"无等价物，按未命中走新选区。

## 验证

- Replay：`docs/migration/replays/d02-original-selection-granular-grab.mjs`
  （24 项静态契约）。
  **2026-09-28 更正**：该 fixture 已随本 ADR 被 ADR-0559 supersede 而移除；
  现行活钉为 `d02-original-selection-tap-clear.mjs`（18 项契约，
  `ftc.i` deselectedIds 语义）。
- `note@default` / `note@ohosTest` HAP 构建通过，无新增 ArkTS 错误。
