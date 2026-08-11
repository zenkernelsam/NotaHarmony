# Phase 85 修复总结：原版 Math 编辑 Consumer

日期：2026-08-11

基线：`19a4394 fix(selection): honor original group membership`

范围：Math 选区、Group 叶子、变换/擦除/删除、历史、层序与复制粘贴

## 原版证据

- 原版 `u08 implements be5`；Math 与 Text/Image 一样是普通 positionable Block，不是只读渲染结果。
- `fu1/xtc` 在 Group 展开前处理 `be5` positionable，因此 Math 必须能直接命中，也必须能成为嵌套
  Group 的可编辑叶子。
- `u08.u()` 明确实现 copy，携带 LaTeX、颜色及 common position state；复制时丢弃 Math 不符合原版。
- common Block 的 positionLocked 约束选择和位置编辑，Math 不能绕过这一规则。

## 实际修复

- `SelectionState/SelectionTool` 增加 `selectedMathIds`；矩形与套索按 Math world bounds 命中，锁定
  Math 排除。Group resolver 的 available leaf 纳入 Math，Phase 84 的临时含 Math 回退边界已解除。
- 新增 Math 变换和真实四边形擦除几何：drag/scale/rotate 左乘现有矩阵，更新 rotation 与 world
  bounds；擦除按变换后四边形、路径线段和擦除半径判断，锁定 Math 不响应。
- 画布 drag 前快照、取消恢复、选区 overlay、delete/cut、erase 与前后层移动全部纳入 Math。Phase 114
  依据 `mub/td8/rl2` 更正：原版 Selection Flip 是 Image-only `MODIFY_BLOCK`，Math 不参与 Flip。
- ADD/DELETE/TRANSFORM/ERASE 混合历史加入向后兼容的可选 Math 快照；apply/undo、ID/索引/source-state、
  elementOrder 校验和内存估算同步闭环，旧 action 缺字段时按空数组处理。
- Clipboard 对 Math 深复制并生成 fresh ID，平移 transform 后重算 bounds；粘贴和撤销维持
  Stroke/Shape/Text/Image/Math 五类元素相对 z-order，冲突或层序失败会整体回滚。

## 验证

- 扩展 `MathBlockGeometry.test.ets`、`SelectionTool.test.ets`、`PageElementOrder.test.ets` 与
  `StrokeClipboard.test.ets`，覆盖变换/锁定、擦除/锁定、Group Math 叶子、Math 层序和五类 clipboard。
- 新增 `d02-math-editing-consumer.mjs`，覆盖原版证据与生产静态接线。
- 全量桌面 replay：`TOTAL=72 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、真机或设备 Hypium，符合本轮约束。

## 未完成边界

本阶段完成现有 Math Block 的编辑 consumer，不等于公式功能完全结束。LaTeX 内容编辑 UI、原版
CREATE/MODIFY outbound writer、原生公式排版替代与设备像素验收仍待后续；Group clipboard 当前复制
完整叶子但尚不写出新的 Group identity。31/31 入站生产路由保持成立，Goal 继续 active。
