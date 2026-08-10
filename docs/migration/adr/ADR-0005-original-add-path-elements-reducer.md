# ADR-0005：原版 ADD_PATH_ELEMENTS 有序片段与笔迹重建

- 状态：Accepted（actual 子集；estimated 边界已由 ADR-0026 接续）
- 日期：2026-08-10
- 关联：D-02、数据库 v27、ADR-0004

## 背景

原版 `ADD_PATH_ELEMENTS=16` 不是对当前渲染数组做普通尾插。`gd` 以 `qo5` 指向目标 Ink，分别携带真实
`encodedCenterPathElements` 与预测 `encodedCenterPathEstimatedElements`；`q06` 把真实片段包装为以追加 op ID 为身份的
`op7`，按 unsigned `(timestamp, site)` 插入有序结构。只有严格尾追加时可以增量更新缓存；较旧片段晚到时会清空缓存，并从
基础 center path 与全部有序片段重新拼接。预测路径则写入独立 LWW register，不进入真实片段序列。

因此，按网络到达顺序直接修改 `StrokeElementData.pathPoints/cubicSegments` 会在乱序同步时永久分叉；只保存已经拼接的 JSON
也无法重建后续片段的起点。原版 `cq.H()` 计算边界时使用原始 line/quadratic/cubic 的全部端点与控制点凸包；尤其 quadratic
转成等价 cubic 后的控制点位于原控制点内侧，若在转换后才算 bounds 会错误缩小候选区域。

## 决策

数据库升至 v27：

- `original_ink_state` 以 `(noteId, ink timestamp, ink site)` 保存 CREATE_INK 的原始基础 center-path BLOB；
- `original_ink_path_append` 以追加 op `(noteId, timestamp, site)` 为主键，保存目标 Ink 和原始追加片段 BLOB，并建立目标/顺序索引；
- 两表分别级联到 `original_element_z_index` 与 `original_ink_state`。v26 既有 Ink 不做有损反推；缺少基础状态时明确返回
  `ADD_PATH_ELEMENTS_BASE_STATE_MISSING`。

`OriginalCreateInkOperationApplier` 在元素、层序和页面快照的同一外层 inbox 事务中保存基础字节。新的
`OriginalAddPathElementsOperationApplier` 仅开放能够无损映射到当前 Stroke 模型的真实 center-path 子集：

1. 解码必填目标 `qo5`，拒绝空 payload；存在 estimated 片段时整体 DEFERRED，不能把预测数据伪装成真实路径。
2. 通过 `original_element_z_index` 解析稳定 Ink 和页面 SeqId，并要求目标是唯一 live snapshot 或远端删除归档中的 Stroke。
3. 从基础 BLOB 和既有片段按 unsigned op ID 重建期望几何；与当前持久化 geometry 不一致时返回分歧，不覆盖未知本地修改。
4. 将候选片段加入同一有序序列后再次完整重建。每个片段以前一有序片段终点为起点，保留原始控制点凸包；乱序插入会正确
   重连所有后续 cubic 的 `p0`。
5. 在同一事务内保存原始片段、替换 stroke payload、推进 content revision，并失效 live 或 archived 页的笔迹搜索状态。
   reducer 不写本地 `operation_log`，也不进入 Harmony Undo/Redo。

当前继续 DEFERRED：estimated center-path register、包含 move 的多 component 片段、VARIABLE 路径缺失逐点属性、Pencil splats、
Tape，以及没有 v27 基础状态的历史 Ink。`MODIFY_INK` 的独立字段 LWW register 和 center-path replacement 将在后续阶段实现；替换
基础路径时必须保留已有 append rows，并从新基础路径重新构建，不能删除追加历史。

后续 ADR-0024/0025 已开放 Pencil actual ADD/MODIFY；ADR-0026 进一步以 `q06.d`、`d16.h` 和 `s06.Q()` 的直接证据开放
estimated LWW register。因此上面的 DEFERRED 描述仅是本阶段边界，不再代表当前实现状态。

## 后果与验证

- 同一组追加 op 无论到达顺序如何，真实中心路径、后续 segment 起点和 bounds 都按原版 op-ID 顺序收敛。
- live page 与远端删除归档共享相同重建语义；旧 v26 数据不会被猜测性补写。
- `OriginalInkPathCodec` 现在用原始元素计算基础/追加 bounds，修复 quadratic 转 cubic 后凸包缩小的问题。
- `d02-add-path-elements.mjs` 覆盖真实 `gd/qo5` FlatBuffer、v26→v27、基础状态、乱序重建/重连、quadratic 原始凸包、
  live/archive 搜索失效、estimated/multi-component/missing-state 分支、几何分歧、故障回滚、无本地日志与级联删除。
- ArkTS fixture 和 DDL 契约已注册；设备 Hypium 与真实远端乱序流仍留待设备/服务联调，不据此宣称 D-02 完成。
