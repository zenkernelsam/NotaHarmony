# 原版证据：选中态 pointer-down 的元素粒度抓取（stc / ej9 case18）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- 主题：选区已存在时的 pointer-down 分发——命中哪个元素就抓取哪个元素（或其
  所属组），而不是拖拽整个选区。
- Phase 589 依据。

## 1. `dl1.java` case2 — pointer-down 分发链

`dl1.b(...)` 在 ACTION_DOWN（case2）上的顺序：

1. `xtcVar.b(jE)` — Tape 探测（ej9 case20，Phase 586 已对齐）。
2. `ktcVar = fvbVar.h.getValue()` — 当前交互状态；`ftc` = 选中态。
3. `ftcVar.h` 为真（选区可见）时：
   - `ptcVarA3 = xtcVar.a(jE, ftcVar.g)` — 取该点最上层命中（`g` 为选中集，
     仅作过滤参数；返回值仍可能不在集内，随后用 `set.contains` 判定）。
   - `otc` 命中且 `set.contains(vndVar.I.getId())` →
     `ttcVar = new stc(ys2.P(vndVar.I.getId()), null)` — **单元素抓取**。
   - `ntc` 组命中（`cqc`：`b` = 组内元素 id 集，`a` = 组键），组内任一成员
     ∈ set → `ttcVar = new stc(cqcVar.b, cqcVar.a)` — **整组抓取**。
   - 未命中元素：`yxi.e(cmbVar, jE, ftcVar.d, fi3.b(cmbVar))`（cmb = 选区
     覆盖层/菜单区域）为真 → `utc`（消费、无动作）；否则 `qtc` →
     `z39(xtc, 17)` —— 手势继续走新选区流程。

要点：**"按在选框内"不等于"拖拽整个选区"**。只有按在选中元素（或其组）
上才进入拖拽；按在选框空白处落入 `qtc` → 新选区手势。

## 2. `ej9.java` case18 — 抓取语义

```java
Set set3 = stcVar.a;                       // 被抓取的 id 集
ftc ftcVar = fvbVar.h.getValue() as ftc;
Set setX1 = ftcVar.m;                      // 组列表
if (qo5Var2 != null) {                     // 组抓取时剔除被拖组
    … ba6.o(((cqc) obj2).a, qo5Var2) …
}
ftc ftcVarJ = ftc.j(ftcVar, …,
    ys2.H(ftcVar.g, set5),                 // g ← g − 被抓取集
    false,
    ys2.J(ftcVar.i, set5),                 // i ← i ∪ 被抓取集
    …, set4, set4, 3775);
if (ftcVarJ.g.isEmpty()) fvbVar.a();       // 选区空了 → 清态
else fvbVar.a.d(ftcVarJ);
```

- `ftc.g` = 选中集；`ftc.i` = **正在移动的子集**（moving set）。
- 抓取 = 把命中元素**从 g 移到 i**；其余选中元素留在 g 原地不动。
- `nze.java:103`：`ftcVar.i` 作为 `set5` 传入 `aeg`（手势应用协程）——
  拖拽变换只落到 `i` 上。
- `i` 与 `g` 都属于选中态，松手后被拖元素仍是选中状态（仍在 `i` 中渲染）。

## 3. `xtc.a(jE, set)` 的命中对象

- `otc` — 单个元素命中（`vnd` 包装，`I.getId()` 为元素 id）。
- `ntc` — `cqc` 组命中（同一点覆盖同组多元素时聚合）。
- `vtc`/`wtc` — 覆盖层部件（手柄/菜单，`wtcVar.a` = cmb）。
- `v09` 种类过滤在 `xtc.b` 中已见（INK+SHAPE）；`xtc.a` 则面向全元素
  （`fu1` 区域查询对 Block 类元素走逆仿射局部矩形，`BlockHitGeometry`
  已对齐）。

## 4. Harmony 对齐点（Phase 589）

| 原版 | Harmony |
|---|---|
| `xtc.a(jE, set)` 最上层命中 | `hitTestSelectedElementIds`：`materializePageElements` 逆序（最上层先）逐类命中 |
| `otc` 元素命中 | STROKE→`eraserEngine.hitStrokeAtPoint`；SHAPE→`pointHitsShape`；TEXT/IMAGE/MATH→`pointHitsAffineBlock(localBounds, transform)` |
| `stc({id})` 单元素抓取 | `grabElements([hitId])` → `movingIds` |
| `stc(cqc.b, cqc.a)` 组抓取 | `expandGrabToSelectedGroup` → `resolveOriginalSelectedGroupLeaves` |
| `ftc.i` moving set | `SelectionState.movingIds`；`movingSubsetOf` 收窄变换与撤销目标 |
| `qtc → z39` 未命中 → 新选区 | 命中失败 → `beginSelection`（与既有路径相同） |
| `utc` 覆盖层 noop | `isInSelectionMenu` 提前 return（原有路径） |

## 5. 有界偏差（记录于 ADR-0558）

- 抓取拖拽期间选框（`selectionRect`）仍覆盖整个选中集，不会缩到 `g` 的
  剩余元素上——原版 `ftc` 重建后覆盖层以 `g ∪ i` 还是仅 `g` 计算无静态
  定论，视觉差极小。
- `planSelectionSnap` 的锚点仍取整个选区边界而非被抓取子集边界。
- `cqc` 是原版查询期动态聚合；Harmony 只对持久 `selectionGroups` 做组
  粒度展开，动态"多点覆盖同组"的等价物不存在，按未命中处理（新选区）。
