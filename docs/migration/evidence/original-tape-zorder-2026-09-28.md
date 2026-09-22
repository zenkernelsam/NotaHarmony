# 原版 Tape 元素 z-order 规则解码（2026-09-28）

阶段：Phase 582。对象：原版 tape（REVIEW/胶带）元素在渲染序中的特殊
排序规则。

## 1. 证据（decompiled_1.0.3/sources/defpackage）

- `ly3.k()` = isTape：`s06.java:536` `return this.k == u16.TAPE`；
  `n5d.java:62` `this.w = Y() == u16.TAPE`（ShapeImpl 同样实现）。
- `vnd.compareTo`（元素有序集比较器）：
  ```java
  boolean zK = ly3Var.k();                    // this is tape?
  if (zK != ly3Var2.k()) {
      return ly3Var2.k() ? -1 : 1;            // 对方是 tape → 我排前
  }
  // 否则按 (zIndex-register, id) 常规排序
  ```
  即 **tape 元素永远排在非 tape 元素之后渲染**（视觉置顶），与
  zIndex 无关；tape 之间保持常规排序。
- `dm2.java:52`：CreateInk 校验 "Cannot specify a TapePattern while
  Tool is not Tape" —— tapePattern 仅属 TAPE 工具产物。
- `g5f.g` = {COLOR, WIDTH, TAPE_PATTERN}：REVIEW 工具的
  ToolState 可编辑属性集（tape_pattern 列已于 Phase 576 入库）。

## 2. Harmony 侧改动

`PageElementOrder.materializePageElements`：物化后按"是否 tape"做
稳定分区——笔画 `renderSpec.tapePattern` 非空、形状
`originalTool === 3`（InkTool 枚举 Tape=3）者移至末尾，保持相对
顺序；transient 进行中的笔画仍在最后（对应原版在制笔迹置顶）。

## 3. 语义影响

tape 胶带条用于遮盖内容（study tape），原版保证其永远盖住下层
笔迹/图片/文本，不受 z-order 操作影响。此前 Harmony 按持久化
zIndex 渲染，若对 tape 之下元素执行置顶操作会导致遮盖失效；
本阶段对齐。

## 4. 范围外（后续阶段）

- REVIEW 工具的笔画创建链路（`getRenderSpec` 未发 tapePattern）、
  pattern picker、hide/reveal 全局开关、点按揭示——仍待解码/实施。
- `vnd` 排序集合同时驱动命中测试路径的可能性未逐调用点核完；
  本阶段只对齐渲染物化序。

回放：`d02-original-tape-zorder.mjs`。
