# Phase 84 修复总结：原版 Group 选区 Consumer

日期：2026-08-11

基线：`f9d75aa fix(sync): preserve original shape rich text`

范围：Group 当前状态读取、顶层/嵌套选区展开、整体变换接线、Shape positionLocked 物化

## 原版证据

- `gtc/cqc` 保存 selected Group identity、成员叶子与整体 bounds；Group 不是绘制元素。
- `xtc` 在直接命中后调用 `fu1.c()`。`fu1.c()` 以 `so5.a()` 选择最新包含组，向上找到顶层 Group，
  再递归展开嵌套 Group；已删除 Group 不进入映射。
- `lg2.c()` 复制时递归补齐嵌套组，缺失/非法成员不会被伪装成完整组。
- Shape 的 `n5d.t()` 是 positionLocked；此前 Harmony 已保存寄存器，却没有写入 Shape snapshot，
  导致锁定 Shape 仍可能被选中。

## 实际修复

- 新增纯模型 Group resolver：直接命中任一成员后，按 timestamp/siteId 选最新包含组，向上解析顶层
  Group，递归展开全部叶子并去重；同时处理嵌套、重叠组与循环检测。
- `StrokePersistence` 从 `original_group_state.members_value` 读取当前 LWW 成员，LEFT JOIN canonical
  visibility winner 排除 tombstoned Group；单条损坏 Group 被隔离，不拖垮页面加载。
- SelectionTool 在矩形/套索命中后执行 Group 解析，把完整叶子重新分类为 stroke/Shape/Text/Image，
  并在 `SelectionState` 保存顶层 `selectedGroupIds`；拖动完成后 Group identity 不再丢失。
- 缺失、跨当前页、循环、锁定或编辑器尚不支持的成员会使整组展开失败，只保留直接命中实体，避免
  “半组变换”损坏布局。当前 Math 尚无完整编辑生命周期，因此含 Math Group 使用该安全回退。
- Shape snapshot 现在物化 positionLocked，type 19 重建也保留当前寄存器值；Shape clone 与包校验同步
  支持可选 boolean。旧/本地 Shape 缺字段时按 unlocked 处理。

## 验证

- 新增 `OriginalGroupSelection.test.ets`，覆盖最新组/site tie、嵌套顶层展开、缺失与循环回退；扩展
  `SelectionTool.test.ets`，覆盖“只命中一个成员却选中完整组”和锁定 Shape 排除。
- 新增 `d02-group-selection-consumer.mjs`，执行同构解析、SQLite tombstone 查询与生产静态接线断言。
- 全量桌面 replay：`TOTAL=71 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、真机或设备 Hypium，符合本轮约束。

## 未完成边界

本阶段完成的是 Group-aware selection 以及现有可编辑 stroke/Shape/Text/Image 叶子的整体变换，不等于
Group 全生命周期完成。CREATE/MODIFY/ungroup outbound writer、保留 Group 结构的 copy/paste/export、
Math 的 selection/transform/undo/clipboard，以及完整私有包 CRDT export 仍待后续。31/31 入站生产路由
保持成立，Goal 继续 active。
