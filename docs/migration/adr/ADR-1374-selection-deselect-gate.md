# ADR-1374 — 选区种类门控：DESELECT 仅 isf 型选区装配

## 状态

已接受（Phase 1439）。

## 背景

原版 1.4.2 元素选择菜单由 `urf` 装配器按 `msf` 选区类型条件装配
`wqf` 枚举行。DESELECT（进入"点按移除"模式 `dhb` case20 → `ftc.h`）
**仅当 `msfVar instanceof isf` 时加入菜单**；点选单元素（`lsf`）、
点选组（`jsf`）、进行中套索（`hsf`）均不出现该行。

`msf` 四种实现：

- `isf`：绘制完成（`hsf`→`isf`，`z6c` 转换）或集合型程序化选区
  （`mud` set-select、`lb8` 变换、`j01` 粘贴结果）。
- `lsf`：单元素选区——`ch1.java:155` 文本点选、`hmb.i(t87)` 通用
  单实体选择。选区菜单无 DESELECT。
- `jsf`：组点选——`ch1.java:178`、`j01:87`。选区菜单无 DESELECT。
- `hsf`：进行中套索——`j01:75` "Paste attempted on in-progress lasso
  selection" 即证。完成后经 `z6c` 转 `isf`。

`j01.java:59-90` 为穷尽分支：粘贴到既有选区时**按原种类保种**
（isf→isf、lsf→`new lsf`、jsf→`new jsf`、hsf→拒绝并 warn）；无既有
选区时粘贴集合经 `mud` 路径产 `isf`。

## Harmony 缺口（修复前）

`SelectionState` 无来源标记——无法区分"绘制完成/集合程序化"与
"点选"选区。`SelectionOverlay` 的 DESELECT 行无条件装配，点选单元素
与点选组也显示该行，与原版 `urf` 不符。此外 `enterDeselectMode` 无
种类检查，能力本身可被绕过菜单触达。

## 决定

在 `SelectionState` 加 `supportsDeselectMode` 布尔标记（记录选区种类
而非基数——单元素集合与单元素点选基数相同但种类不同，故不能以 id
计数推断）：

- `beginSelection`/`deselect` 复位 `false`。
- `finalizeSelection`（套索/矩形完成提交）命中非空 → `true`
  （hsf→isf 等价）；空命中丢弃不转 isf。
- `selectElementIds` 加可选 `drawnKind?: boolean`：
  `false`=点选型（lsf/jsf），`true`=集合型（isf），`undefined`=保种。
  全空调入（等效取消）强制复位。
- `enterDeselectMode` 同判兜底（isf 专属能力，不只是菜单行）。
- `NoteCanvasView` 全部 `selectElementIds` 调用点按 j01 语义标注：
  `applyTapSelect`→`false`；select-all 两条→`true`；粘贴两处→
  `selectionVisible ? undefined : true`；图片插入→
  `selectionVisible ? undefined : finalImages.length > 1`；数学插入→
  `selectionVisible ? undefined : false`；裁剪重断言与变换重断言
  省略参数（保种）。
- `SelectionOverlay` 加 `@Prop canDeselect` 门控 DESELECT 行；
  `NoteCanvasView` 以 `@State selectionCanDeselect` 镜像
  `state.supportsDeselectMode`。

## 已知近似

`ty9.handleAddImageFromClipboard` 等插入路径的 select 实现在反编译层
未完全展开（suspend lambda 方法引用）。单图片插入按 `hmb.i`→lsf
类推判 `false`（DESELECT 隐藏）；多图/集合插入按 `mud`→isf 判 `true`。
若原版对单图片插入也产 isf，该行差异仅限"单图插入后 DESELECT 可见性"
一处，且属保守方向（隐藏优于虚显——虚显会触达无实体死路径）。

## 后果

- 点选单元素/组菜单与原版一致——无 DESELECT 行。
- 套索/矩形完成选区、全选、粘贴集合选区保有 DESELECT 行。
- deselectMode 仅 isf 可达，confirm/cancel 快照语义不变。
- 23 项 `wqf` 枚举的其余装配差异此前已由 ADR-0645 全表登记。

## 验证

- `docs/migration/replays/d02-selection-deselect-isf-gate.mjs`
  19/19 静态断言（字段/复位/置真/三态标注/门控/镜像/文档闭环）。
- 全量 Replay 基线与双 HAP 构建见 Phase 1439 report。
