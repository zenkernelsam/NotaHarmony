# Phase 1367 — 库 FAB 菜单外侧点击关闭（DropdownMenu 等价）

## 原版证据（`cwi.b` → `apb.d` → `zs.a`）

`cd` case 0 的速拨项经 `cwi.b` 包进 `apb.d(expanded=z, onDismissRequest=function4,
content)`，`apb.d` 内部调 `zs.a(z, dismissFn, …)`——即 Compose `DropdownMenu`
弹出层：点外侧触发 `onDismissRequest` 关闭菜单，且不穿透到下层。

## 差距

Harmony 原 `FabButton` 把 chips 直接放进 overlay 的 Column，无关闭层——
菜单展开时点在笔记列表上不会关闭（与 DropdownMenu 行为不符）。

## 修正

`FabButton` 顶层改 `Stack(alignContent:BottomEnd)`：`createMenuOpen` 为真时
先铺一层 100%×100% 透明 `Column`（`onClick→createMenuOpen=false`），chips+FAB
置于其后（Stack 后子项在上，chip 点击仍可达）。关闭时该层不渲染，Stack 透明
区域不拦触（默认 hitTest），仅 FAB 可点——无回归。

## 验证

`d02-library-fab-order.mjs` 断言 Stack 宿主 + 关闭层：27/27。
