# Phase 1419 证据：原版选择工具 Box/Free 双模式 toggle

反编译基线：`decompiled_1.4.2`（`sources/defpackage`、`resources/res`）。
本节钉住选择工具二级配置条中的**双模式 toggle**——Harmony 此前为
单一按钮（标签随当前模式切换），与原版两枚独立 toggle 不符。

## 1. 宿主：`i6n` 二级工具条 → `iw4` → `rnm.c`

`i6n.java:1553` 起：对当前工具的 `kqi` 选项列表
（`e52.X3(k31.E(wsiVar), ttb(28))` 排序）逐项以 `iw4` 包裹后经
`f(i5, z2, content)` 送入二级槽位。选择工具的选项之一即 `rnm.c`。

## 2. `rnm.c` 本体（`rnm.java:3713-3758`）

```java
public static final void c(boolean z2, w8a w8aVar, bz5 bz5Var, …) {
    // z2 = 当前是否 Freehand 模式
    d0f d0fVarA = b0f.a(new c90(8.0f, true, new js4((byte) 5)), bw6.P, …); // Row 间距 8dp
    hdc hdcVarA = ((j87) se3.x(nc6Var).H).h.a(nc6Var);          // selectbox_outline
    String strW0 = oye.w0(nc6Var, R.string.ui_tools__select_box_label);   // "Box"
    String strW1 = oye.w0(nc6Var, R.string.ui_tools__select_rect_mode);   // a11y
    boolean z3 = !z2;                                            // 非 freehand → Box 选中
    objS = new w5e(bz5Var, (byte) 9);                            // → FALSE
    w5n.b(hdcVarA, strW0, strW1, z3, null, null, objS, …);
    hdc hdcVarA2 = ((j87) se3.x(nc6Var).H).i.a(nc6Var);          // selectfreehand_outline
    String strW2 = oye.w0(nc6Var, R.string.ui_tools__select_freehand_label); // "Free"
    String strW3 = oye.w0(nc6Var, R.string.ui_tools__select_freehand_mode);  // a11y
    objS2 = new w5e(bz5Var, (byte) 10);                          // → TRUE
    w5n.b(hdcVarA2, strW2, strW3, z2, null, null, objS2, …);
}
```

- 行内**无前置 "Selection" 文本标签**——两枚按钮自带 label。
- `w5e` case 9/10（`w5e.java:48-51`）分别 `invoke(Boolean.FALSE/TRUE)`：
  Box → 矩形模式；Free → 自由模式。

## 3. `w5n.b` 按钮本体（`w5n.java:27+`）

签名 `b(hdc icon, String label, String cd, boolean selected, …)`：
- `x5n.a` 按钮（shape `t8a.F` 圆角、cd 挂 `str2`）。
- 内容 lambda `vqf`：`i87.b(icon,…)` + `d4i.b(label,…)` 横向排，
  图标/文字取 `nta.a.c.b` 内容色。
- 选中态：`z==true` 时 `j = nta.c(nc6Var2).a.d.a`（accent 底）；
  非选中 `p52.j` 中性底。

## 4. 图标资源

| j87 字段 | drawable | 视口 | 填充 |
|---|---|---|---|
| `H.h` | `ui_designsystem__selectbox_outline` | 24×24 | `#444f60` 单层 |
| `H.i` | `ui_designsystem__selectfreehand_outline` | 24×24 | `#444f60` 单层 |

pathData 已逐字提取进 `ToolGlyphs.ets` 的 `selectbox`/`selectfreehand` 项。

## 5. Harmony 落地（`EditorToolbar.ets`）

- `isSelectionActive` 分支首行改为 `Row({ space: 8 })` + 两枚
  `SelectionModeButton`（`@Builder`，对应 `w5n.b`）：
  - Box：`glyph='selectbox'`、`select_box_label`、`select_rect_mode` a11y、
    `selected=!selectionIsFreehand`、onTap → `setSelectionIsFreehand(false)`。
  - Free：`glyph='selectfreehand'`、`select_freehand_label`、
    `select_freehand_mode` a11y、`selected=selectionIsFreehand`、
    onTap → `setSelectionIsFreehand(true)`。
- 按钮选中态 `accent` 底/`onAccent` 前景，非选中 `control` 底/
  `textPrimary` 前景；沿用 `toolStateLoading + photoImportLeaseActive`
  双门控（既有租约约定）。
- 移除 Harmony 自造的 `"Selection"` 前置文本与单钮切换；
  `freehand`/`rectangle` 资源键随之清除（无其他引用）。
- 第二行样式钮（mono/taper/dash/dots）不变。

Replay：`docs/migration/replays/d02-original-selection-mode-toggle.mjs`
（27 项锚定：rnm.c 双钮字段、w5e 9/10 派发、j87 图标映射、
w5n.b 选中色、Harmony 双钮结构与门控、两 locale 资源）。
