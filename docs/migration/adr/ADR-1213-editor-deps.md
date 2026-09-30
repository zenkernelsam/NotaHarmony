# ADR-1213：编辑器外围依赖面

## 状态

已接受（Phase 1269）。

## 决策

`wc5`/`hi2`/`el8`/`in6`/`of1`/`n03` 编辑器依赖 → Harmony
`pasteboard`+`emitter`+`ScrollBar` 装饰器。

## 理由

`wc5`=ClipboardManager/`hi2`=服务 iface；`el8`=流发射
器（emit/tryEmit）；`in6`=`a(rle)` 焦点监听；`of1`=
滚动条装饰 Modifier 工厂（@Composable uz4）；`n03`=
combine 收集器 —— 编辑器外围服务完整接线。

## 后果

Harmony 外围服务 = pasteboard+emitter+ScrollBar ——
依赖面语义保真。
