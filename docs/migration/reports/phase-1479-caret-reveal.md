# Phase 1479 报告 — 文本编辑光标可见性滚动（jyh.g + lcn.h）

## 原版行为（decompiled_1.4.2）

`jyh.g(zle)`：编辑态每发射一次按 `li8` 动作分派——

| li8 | 行为 |
|-----|------|
| SELECT_ALL(0) | 不滚动 |
| PAGE_UP/DOWN(1/2) | `gfc`：`x(l() ∓ 0.9·视口高 + m(rect, 10%内缩视口))` |
| OTHER(3) | caret 矩形未全落 5% 内缩视口 → `mfc.u(rect, 0.1f)` |

caret 矩形：`lcl.h(l74)` 行布局度量 → 1dp 宽、行高矩形。
`lcn.h`：`kck.b==Bottom` 时矩形底边扩展 `336dp/zoom` →
`mfc.u(rect,0)`（IME 避让）。

## Harmony 实现

- `caretRectAtIndex`：`caretIndexAtPoint` 的逆运算（同 `layoutLines`
  + `measureRange` 核）→ world 坐标 1 单位宽 caret 矩形。
- `revealEditingCaret()`：全含判据 = 5% 内缩视口；位移 = 10% 内缩
  最小补差 → `panBy(−jM)`；有效视口底边减
  `getWindowAvoidArea(TYPE_KEYBOARD)` 键盘高（lcn.h 并入）。
- `onCaretChange(offset, selectionStart)` 携带选区锚定端——
  SELECT_ALL（选区覆盖全部草稿）不滚动。
- `editorWindow` 于 `aboutToAppear` 经 `getLastWindow` 缓存，
  reveal 同步路径可查键盘高。
- `onCaretChange`/`onDraftChange` 双通道触发。

## 登记差异

- 无滚动动画（`panBy` 即时；原版 `mfc.x` 挂起动画）。
- PAGE_UP/DOWN 走原生 TextArea 页移 → OTHER 支（无 ∓0.9h 预滚）。
- SELECT_ALL 门 = 全选覆盖近似谓词。
- `kck.b==Top` 顶部锚定场景未实现（Harmony 无对应物）。

## 验证

- fixture `d02-original-caret-reveal.mjs`：**26 checks OK**
  （caretRectAtIndex 布局复用、折返边界、transform AABB、
  回调透传、门集、5%/10% 几何、IME 视口收缩、双通道接线、
  reveal 可执行模型）。
- `note@default` assembleHap：BUILD SUCCESSFUL。
- 全量基线与 `note@ohosTest` clean：见提交记录。
