# Phase 111 修复总结：原版本地选区 MODIFY_POSITIONS 出站

## 原版证据

- 原版 `avc.l/o/p/q/t` 分别处理选区平移、旋转、缩放及组合变换；一次手势结束把多个目标组装成一个
  `je8`，`je8VarQ.j() > 0` 时以 durable `wq9` 提交。
- `w0j.e` 的单目标 row 有 target、page、origin、nullable rotation setter、nullable scale setter、
  nullable uint64 zIndex 六字段；`x0j.m/n` 将 rows 写成 type 24，未改变的 register 保持 absent。
- 原计划继续 center-path replacement，但复核 1.0.3 没有找到其生产调用；选区变换则有明确用户入口和
  durable 提交链，因此本阶段改做证据更强、价值更高的 MODIFY_POSITIONS outbound。

## 已完成修复

- 新增原版 type-24 FlatBuffer encoder，支持批量 row、page/origin、nullable rotation/scale setter 与完整
  uint64 zIndex；拒绝空批次、重复 target、空更新、非法 identity 和非有限几何。
- `StrokePersistence` 新增严格 classifier：页面必须仍与原版 identity/order 完全对齐；变化目标必须是
  canonical Ink、Text/Image/Math Block 或 Shape；除 transform 及其派生 bounds/rotation 外逐字节不变。
  矩阵必须能分解为正 scale、rotation、origin，shear、reflection、perspective、混合本地内容或其他字段
  修改全部保守走既有 Harmony fallback。
- 普通保存和 grouped Undo/Redo 都在共享 persistence mutex/单事务内完成：分配 operation identity、生成
  完整本地 `uq9`、调用生产 type-24 reducer、写同一 bytes 到 upload-immediate operation log、精确
  reconciliation，再写 Harmony history companion。一次选区手势只产生一条批量原版 position operation。
- 本地同页手势不改 page identity 或 zIndex；只有 origin 实际变化时才写 page+origin，rotation/scale 也只在
  变化时出现，避免制造原版没有的多余 LWW winner。
- 边修边审修复两项相邻缺陷：`SelectionTool.applyTransform` 不再丢失 Stroke 的 `originalCreate`；全 canonical
  原版目标变换及其 Undo/Redo 不再错误标记页面为 authoring ineligible，下一笔仍可走 CREATE_INK outbound。
- 原版 wire 几何是 float32，而 Harmony 矩阵是 JS number。Ink/Block reducer 的 source-state 比较改用严格
  相对 epsilon，Block 派生 bounds/rotation 同步处理舍入，避免第二次合法变换被误判为状态分歧；不放宽
  classifier 对 shear/reflection/非位置字段的拒绝。

## 验证

- ArkTS fixture 新增双目标 type-24 round-trip，覆盖 page/origin、非空与显式 null setter、最大 uint64 zIndex；
  clean `note@ohosTest` 编译已经证明 fixture 与生产代码进入同一 ArkTS 图，未运行 Hypium。
- clean 默认包首次把完整 Block/Shape position reducer 拉入严格 ArkTS 编译图，暴露并修复 28 个此前被增量图
  遮蔽的类型错误：匿名结构改为具名模型、跨模型结构赋值改为显式构造、rich-text style run 改为具名深拷贝，
  reducer 的任意异常改为明确包装。没有绕开或删除生产 reducer。
- 专项 replay 输出：
  `localModifyPositions=original-batch-position-writer-history-envelope-rollback`。
- 全量桌面 replay：`TOTAL=97 FAILED=0`。
- 执行 `hvigor clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，均为 `BUILD SUCCESSFUL`；只有
  项目既有 warning，两套 unsigned HAP 均已落盘。未启动模拟器、虚拟机、真机或 Hypium。

## 仍待后续

- Harmony Flip 当前会产生 reflection；原版已核实的 selection writer 生产链不足以证明单轴反射语义，因此继续
  使用保守 fallback，不伪装成 type 24。
- Group CREATE/MODIFY/ungroup 与保组复制、Block/Text/Image/Math/Shape 的其他本地 outbound、完整 `.note`
  CRDT import/export、私有认证 upload/ACK、transient collaboration 和集中设备验收仍待后续。Goal 保持 active。
