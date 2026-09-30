# Phase 1367 — 库 FAB 菜单外侧点击关闭

## 摘要
原版速拨菜单是 `apb.d`/`zs.a` 的 DropdownMenu 弹出层，点外侧经
`onDismissRequest` 关闭且不穿透。Harmony 原无关闭层。`FabButton` 改
`Stack(BottomEnd)`：菜单开时铺全屏透明 `Column`（点外侧→`createMenuOpen=false`），
chips 在上层仍可达；关闭时透明区不拦触。专项 d02-library-fab-order 27/27。
