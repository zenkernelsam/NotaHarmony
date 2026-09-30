# ADR-0659 — 库 FAB 菜单外侧点击关闭
## 状态
已接受（Phase 1367）。
## 背景
原版速拨=Compose DropdownMenu（apb.d→zs.a），外侧点击 onDismissRequest 关闭。
Harmony overlay 无此关闭层。
## 决定
`FabButton` 用 Stack(BottomEnd) 宿主，菜单开时铺全屏透明关闭层（onClick→关），
chips 在上；关闭时无该层、透明区不拦触。
## 后果
外侧点按关闭菜单，与 DropdownMenu 一致；底层内容不被误触。
## 验证
d02-library-fab-order 27/27。
