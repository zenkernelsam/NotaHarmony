# Evidence — 空白处长按菜单项集 {PASTE, SELECT_ALL}（yqa.f）

- 日期：2026-09-28；Phase 622
- 来源：`decompiled_1.0.3/sources/defpackage/{yqa,tqe,eh5,br2}.java`

## yqa.f 菜单构建（yqa.java:180-215）

```java
// 项源 iterableM0：
if (z3)                              → au1.T1(rbb.m())        // 剪贴板动态项
else if (a2gVar3.equals(a2gVar))     → m18.m0(PASTE, SELECT_ALL)  // 常态两项
else                                 → tqe.a()                // 全量项
// 过滤循环（tqe.ordinal()）：
//   ordinal==2（PASTE）     需 zHasPrimaryClip
//   ordinal==6（SELECT_ALL）需 z4 = eh5.b
boolean zHasPrimaryClip = tr1Var.a.a().hasPrimaryClip();  // 剪贴板有内容
boolean z4 = ((eh5) this.f.i.getValue()).b;               // REMOVE_HIGHLIGHT 门
// z（200ms 交互窗，g39.b）内 z=false 分支静默 return（Phase 620 已对齐）
```

- `tqe.java`：菜单项枚举含 `PASTE(2)`、`SELECT_ALL(3)`（构造参数为
  项 id；过滤用的 `ordinal()` 值 2/6 按声明序）。
- `eh5.java`：`eh5(long j, boolean z)`——状态对（j=目标标识，
  z=b 标志）。`br2` 默认态 `eh5(gh5.a, false)`；`aa6`/`fm7`/`cve`
  构造 `eh5(id, true)`。`z4` 门控的是 **ordinal6 = REMOVE_HIGHLIGHT**
  （文本菜单项，≈长按目标含高亮时才产出）——不在 {PASTE,SELECT_ALL}
  项集，与空白处菜单无关。
- **修正**（本 Phase 复查 tqe 序数后）：ordinal6=REMOVE_HIGHLIGHT
  而非 SELECT_ALL（SELECT_ALL ordinal=3 无条件通过过滤）——
  SELECT_ALL 在空白处菜单中**无门**（空页点击=空选，等价 no-op）。

## 语义结论

原版空白处长按菜单 = **{PASTE, SELECT_ALL}**（顺序固定）：

- **PASTE**：剪贴板有内容即产出（`hasPrimaryClip`——元素负载与
  系统剪贴板图片任一）；点击在长按锚点粘贴。
- **SELECT_ALL**：本项集中**无门**（固定产出）；点击全选页面
  元素 → ftc 多选（未分组实体平铺 + 顶层组整体入选）。
- 两项均可被 `g39.b()` 200ms 交互窗抑制（Phase 620 已对齐外层）。

## Harmony 对齐前差距

`ClipboardPasteContextMenu` 仅一项：「系统剪贴板图片粘贴」，且
只在 `!canPasteClipboardNow() && canUseOriginalClipboardImage()`
时产出——元素剪贴板有内容时菜单为空（元素粘贴经长按不可达），
SELECT_ALL 完全缺失。

## Harmony 对齐（NoteCanvasView.ets）

- `ClipboardPasteContextMenu`：`recentInteractionGateActive()`
  外层门内按序产出——
  - PASTE：`canPasteClipboardNow() ||
    canUseOriginalClipboardImage()`（hasPrimaryClip 等价）；
    点击时元素剪贴板优先 `pasteClipboard(clipboardPasteTarget)`
    （长按锚点），否则 `startOriginalClipboardImagePaste()`。
  - SELECT_ALL：无门固定产出（原过滤循环对 ordinal3 放行）→
    `selectAllPageElements()`；空页早退 = 原版空选等价。
- `selectAllPageElements()`：`resolveOriginalGroupSelection(
  allIds, allIds, selectionGroups)` 归并——未分组实体平铺 +
  顶层组 id → `selectElementIds` → ftc 多选 → overlay+渲染。
- 字符串：`select_all` = "Select All" / "全选"（base+zh_CN）。

## 边界

- 原版 `z3` 分支（剪贴板动态项 `rbb.m()`）与 `tqe.a()` 全量
  项集属更广的剪贴板项模型（多负载/富文本等），Harmony 无对应
  载荷类型——本 Phase 对齐常态两项集。
- 含选区时的长按由选区壳事件（ej9/dhb 体系）处理；Harmony 选区
  动作为常驻浮层菜单（已注册适配），不在此菜单范围。

## 验证

- `d02-original-longpress-menu-items.mjs`：18 断言全绿。
- `d02-original-recent-interaction-menu-gate.mjs`：门结构断言
  更新（门包裹项块），15/15 绿。
