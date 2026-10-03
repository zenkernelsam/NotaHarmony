# Phase 1479 — 文本编辑光标可见性滚动（jyh.g + lcn.h IME 避让）

## 原版证据（decompiled_1.4.2）

### 驱动：`jyh.g(zle)`（`jyh.java:493-545`）

编辑态 `zle` 状态流每次发射 → `g()`：

```java
l63 l63VarH = lcl.h(l74Var, r3jVarR.m() ? r3jVarR.F : r3jVarR.G);
sbe sbeVarJ = yl2.j(xxb.g(l63VarH.b(), l74Var.g),
                    v64.a(1.0f, l63VarH.a()));       // 1dp 宽 caret 矩形
int iOrdinal = li8Var.ordinal();                    // zle.d.h
// li8 = {SELECT_ALL=0, PAGE_UP=1, PAGE_DOWN=2, OTHER=3}
if (iOrdinal != 0) {                               // SELECT_ALL → 不滚
  if (iOrdinal == 1) { gfc byte1; }                // PAGE_UP
  else if (iOrdinal == 2) { gfc byte0; }           // PAGE_DOWN
  else if (iOrdinal != 3) { js4.t(); return; }
  else {                                            // OTHER
    ku7 ku7VarH = u64.h(sbeVarJ, exjVar.a);
    ku7 ku7VarB = oan.b(exjVar.c, 0.05f);           // 视口 5% 内缩
    if (rect 越 ku7VarB) { mfcVar.u(sbeVarJ, 0.1f); }
  }
}
```

- `lcl.h(l74)` = 文本排版 caret 行度量 → `l63`；`v64.a(1f, l63.a)`
  = 宽 1、高为 caret 行高的矩形（文档坐标）。
- `li8` 枚举 = 引起本次编辑态的动作类型（`li8.java`：
  SELECT_ALL/PAGE_UP/PAGE_DOWN/OTHER）。

### 滚动原语

- `gfc byte0`（PAGE_DOWN）：`jI = mfc.i()`（+0.9·视口高），
  `jM = mfc.m(rect, odf.f(jI, oan.b(f(),0.1)))` →
  `x(l() + jI + jM)`——先页滚再把 caret 收入新视口 10% 内缩区。
  `gfc byte1`（PAGE_UP）同款、`mfc.j()`（−0.9·h）。
- `jka byte1`（`mfc.u`）：`jM = m(rect, oan.b(f(),margin))` →
  `x(l()+jM)` 最小位移滚动至可见。
- `mfc.m`：按边补差——`rect.left≤view.left → dx=rect.left−view.left`；
  `rect.right≥view.right → dx=rect.right−view.right`；y 同理。
- `oan.b(rect,f)`：`[a+w·f, b+h·f, a+w(1−f), b+h(1−f)]` 各边按
  f·维度内缩。

### IME 避让：`lcn.h`（`lcn.java:2944`）

`kck.b == vak.G(Bottom)` → caret 矩形 `d += 336dp/zoom`；
`Top` → `b -= 336dp/zoom` → `mfc.u(rect, 0)`——为 IME/底部锚定
UI 预留 336dp 可见区。

## Harmony 实现

- `Canvas2DTextRenderer.caretRectAtIndex(element, ctx, index)`：
  `caretIndexAtPoint` 的逆——同套 `layoutLines`/`measureRange`
  行布局核产出 1 单位宽、行高 caret 矩形（world 坐标，
  `element.transform` 四角 AABB）；折返边界 caret 归下一行。
- `TextBlockOverlay.onCaretChange(offset, selectionStart)`：
  透传选区锚定端。
- `NoteCanvasView`：
  - `editingSelectionStart` 字段 + 复位点同步；
  - `editorWindow`：`aboutToAppear` 缓存 `getLastWindow`；
  - `keyboardAvoidHeightPx()`：`getWindowAvoidArea(TYPE_KEYBOARD)`
    → `visible ? bottomRect.height : 0`；
  - `revealEditingCaret()`：OTHER 门（5% 内缩视口内含判据）→
    10% 内缩最小位移 → `panBy(−jM)`（`pos+=jM`、`scrollY≡−pos`
    符号链，与 Phase 1478 一致）；有效视口底边减去键盘高
    （lcn.h 的语义并入）；
  - 接线：`onCaretChange` 与 `onDraftChange` 双通道触发。

## 登记差异

- 滚动即时完成（`panBy` 直写）；原版 `mfc.x` 为挂起动画——
  时长曲线未测，登记差异。
- li8 动作类型不可逐字复现：SELECT_ALL 以"选区覆盖全部草稿"
  近似；PAGE_UP/DOWN 由原生 TextArea 页移 caret 后走 OTHER 支
  （无 ∓0.9h 预滚，登记差异）。
- IME 预留按实际键盘高（原版固定 336dp/zoom 等效扩展）；
  `kck.b==Top` 的顶部锚定场景 Harmony 无对应物，未实现。
