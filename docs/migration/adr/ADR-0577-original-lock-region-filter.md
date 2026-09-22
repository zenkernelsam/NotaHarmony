# ADR-0577 — 区域选区剔除 positionLocked 元素（fu1.b → jrh.a）

- 状态：Accepted
- Phase 608；对齐 `fu1.b`/`jrh.a`/`cih.a`/`uw2`/`vo2`/`xtc`（decompiled_1.0.3）。

## 背景

原版矩形/套索选区完成（`uw2` case1、`vo2`）走
`f(uh5) → b(锁剔除) → c(组扩展)`：`fu1.b` 在 `ac4.Q`
（POSITION_LOCKED，PRODUCTION 默认开）下剔除 `jrh.a` 为真的
元素——`oy0` 块 `t()`、可锁形状 `cih.a && n5d.t()`；笔迹
`jrh.a(s06)=false` 永不剔除。点按路径（`xtc.a`/`c`/`e`、`xtc.b`
tape 栈选）不经 `b`——锁定元素仍可点选解锁。

Harmony 旧实现：`finalizeSelection` 对 positionLocked 元素照常
收集——套索/矩形可把锁定元素圈入选区并拖动变换，与原版
"锁定元素被区域选区跳过"不符；此前单元测试还把"矩形可选中
锁定块"固化为预期。

## 决策

1. `finalizeSelection` 四类命中循环前置
   `element.positionLocked === true → continue`：
   - 形状/文本/图片/数学：`oy0.t()`/`n5d.t()` 等价字段剔除；
   - 笔迹循环不剔（`jrh.a(s06)=false`，原版笔迹不可锁）。
2. 剔除位于 `resolveOriginalGroupSelection` 之前——保持原版
   f→b→c 次序；被组扩展拉入的锁定成员不再二次过滤（`fu1.c`
   无锁检查，Harmony 组扩展同样不加）。
3. `cih.a`（`!n5d.y` 可锁门控）不单独建模：`y=true` 的不可锁
   形状 `t()` 必为假，`positionLocked === true` 判定等价
   （fail-safe：异常置锁的不可锁形状 Harmony 会剔，原版不剔）。
4. 点按/揭示路径不加过滤（`xtc.a`/`e`/`b` 无 `b`）——锁定元素
   仍可点选，UNLOCK 可达。
5. 单元测试 `SelectionTool.test.ets` 四处同步为原版语义：
   locked 块/形状/图片/数学在区域选区被剔除；组扩展路径不变。

## 偏差

- `lc4.a(ac4.Q)` 可被远程开关关闭；Harmony 按 PRODUCTION 默认
  开启实现，不建开关。
- `n5d.y` 不可锁门控简化（见决策 3）。

## 验证

- `d02-original-lock-region-filter.mjs`：9 断言（四类剔除、笔迹
  不剔、f→b→c 次序、注释锚点、点按无过滤）。
- `SelectionTool.test.ets` 预期同步更新。
- 全量 Desktop Replay 全绿；`note@default`/`note@ohosTest` 通过。
