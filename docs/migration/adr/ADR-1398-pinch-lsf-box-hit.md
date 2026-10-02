# ADR-1398：utf 捏合界内判定 lsf 支用元素包围盒（guf.y rtf(mp4.e(), −c())）

- 状态：已采纳
- Phase：1463（结清 Phase 1457 登记差异「rtf.b().a 界内判定路径」）

## 背景

Phase 1457 移植 `utf` 双指捏合变换时，界内判定复用
`pointInSelectionRect`：单元素选区走 `topmostPageElementIdAt`
元素几何精确命中（笔画距离场 ±5/形状路径）。本 Phase 解码
`guf.y` 坐实原版语义不同——lsf 支构造
`rtf(xnm.d(实体,位置)=mp4 的 e() 包围盒, f5n.c(mp4.b(),−mp4.c())
反旋矩阵)`，判定点经矩阵反旋后 `sbe.a` **半开矩形包含**。

后果：对角线笔画/非满框形状，第二指落在包围盒角部（几何体外）
原版启动 utf，Harmony 漏启动。

## 决策

`tryStartSelectionPinch` 单元素 lsf 分流 `singleElementBoxHit`：
按类型取局部界（笔画/形状 `.bounds`；文本/图/数专用
`textBlockLocalBounds`/`imageBlockLocalBounds`/`mathBlockLocalBounds`）
+ 元素 `transform`，交给 `pointHitsAffineBlock`——其
`inverseAffinePoint`+`pointInHalfOpenRect` 与
`f5n.g(点,反旋)+sbe.a` 逐点等价且覆盖缩放。

ksf 支（isf/jsf）不变：`pointInSelectionRect` 的 drawnRect/旋转系
并集矩形等价 `rtf(ksf.a(),−g())`。

## 登记差异

- 笔画旋转烘进点列（transform 恒等）→ AABB 界略大于原版旋转盒，
  斜笔画角域多命中——数据模型差异，登记不纠。

## 验证

`d02-original-pinch-session-utf.mjs` 24/24；基线 1304/1304；
双 HAP 构建通过。
