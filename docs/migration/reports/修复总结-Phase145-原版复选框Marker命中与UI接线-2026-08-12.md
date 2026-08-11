# Phase 145 修复总结：原版复选框 Marker 命中与 UI 接线

## 原版对照与问题

- 原版 `yqa.d()` 只遍历真实段落的 CHECK_BOX marker，直接复用 `jo3.c()` 的绘制几何；触点到
  marker 中心的距离必须小于半径 `1.5x`，命中后由 `htd/ww2` 在普通光标和选区处理前调用
  `fm7.n(codePointIndex)`。
- Harmony 此前只画出 checkbox 字符，没有任何可点击 marker。默认工具的单击只记录双击候选，用户无法
  产生 Phase 144 已完成的本地 type-28 数据链。
- 边修边审发现旧 `lineEnds()` 只返回行尾：软换行续行会再次取得同一 paragraph decorator，硬换行在
  consumer 使用 `end + 1` 后还可能漏掉续行首字符。基于该结果另写 hit test 会把渲染错误固化两遍。

## 已完成修复

- 将排版结果统一为带 `start/end/paragraphStart` 的 visual line；只有真实段首画 marker，软换行续行不再
  重复 marker，硬换行也不丢首字符。编号、缩进、对齐、前缀测量和正文绘制继续使用同一 Canvas 字体。
- 新增 renderer-owned checkbox marker geometry，中心来自实际前缀位置，半径采用原版 natural line
  height 公式；完整逆 Text 仿射矩阵后按原版 `radius * 1.5` 严格圆形命中，奇异矩阵拒绝交互。
- DEFAULT 工具在普通双击判定前检查最上层未锁定 Text marker。命中后调用
  `toggleOriginalCheckboxAt()`，压入单一 `REPLACE_ELEMENT`，刷新 Undo/Redo、排版与画布并调用现有
  `persist()`；原版对齐页自动进入 Phase 144 type-28 reducer/upload 链。
- 新增旋转、平移、换行和命中边界 ArkTS fixture、ADR-0122 与原版方法体静态 replay。

## 验证与边界

- 专项 replay 输出：
  `checkboxMarkerHit=original-layout-geometry-radius15-shared-wrap-transform-single-tap-history-type28`。
- 全量桌面 replay 为 `TOTAL=131 FAILED=0`；`hvigorw clean` 后严格串行构建
  `note@ohosTest` 与 `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`。未启动模拟器、虚拟机、
  真机或 Hypium。
- 当前 durable canvas 单击链完整；活动编辑覆盖层仍是平台普通 `TextArea`，无法按段呈现与正文共同排版的
  rich marker。此边界不能用不可见宽泛按钮伪装完成，后续需在 rich editor overlay 能原子合并 draft
  text/style 后再接入，Goal 保持 active。
