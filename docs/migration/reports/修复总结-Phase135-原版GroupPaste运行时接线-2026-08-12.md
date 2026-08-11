# Phase 135 修复总结：原版 Group Paste 运行时接线

## 原版对照与问题

- 原版 `lg2.java` 让 `u5j.c()` 为选中图生成新操作，筛选其中的 `CREATE_GROUP`，并在快照到达后恢复
  top Group 选择；Group 图不是一个布尔属性。
- HarmonyOS 此前仅保存 `containsOriginalGroups`，随后走普通 `ADD_ELEMENTS`，nested/top Groups 必然
  丢失。`paste()` 还会在数据库结果出来前增加 `pasteCount`，失败重试会无故继续偏移。
- 边修边审发现旧位移物化会只加新 `dx/dy` 后清零整个 transform，导致已移动/旋转/缩放的源
  Ink/Shape 静默错位；Phase 133 返回值也只含新 Groups，直接安装会抹掉页面既有 Groups。

## 已完成修复

- `StrokeClipboard` 深拷所选 top Groups 的完整 bottom-up 子图，拒绝缺失、环、重复和多父结构；复制
  失败保留旧剪贴板。
- 新增 Group Paste preview 与显式 sequence commit。preview 不改变剪贴板状态；只有 Phase 133 事务
  成功后才消费序号，因此失败不污染后续 Paste 偏移。
- Ink/Shape 将完整相似变换和本次位移物化到原版 CREATE 几何，包含笔宽、Pencil reference 与 splat
  尺寸；不能精确保真的剪切/非等比矩阵明确拒绝，不再静默丢 transform。
- `NoteCanvasView` 在无 UI 预写的情况下完成 plan preflight 与单事务提交；成功后才推入真实 NCP1 专用
  action、安装完整层序/active Groups、选择新 top Groups、刷新渲染。页面 generation 不匹配时不污染
  当前画布。
- 持久层 Paste 结果改为返回全部 active Groups。扩展 `StrokeClipboard.test.ets`，覆盖 Group 图深拷、
  不完整/多父拒绝、失败不消费序号和已有 transform 物化。
- 新增 ADR-0112 与 `d02-original-group-paste-ui.mjs`，并升级旧单元素 Paste replay 的 Group 门禁。

## 验证与边界

- 四条相关专项 replay 均通过；全量桌面 replay 为 `TOTAL=121 FAILED=0`，`git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 warning。
- 未启动模拟器、虚拟机、真机或 Hypium；新增 Hypium fixture 已写入但未在设备 runner 执行。
- Image/Math、Styled Text、Shape RichText Group Paste 继续由生产编码门禁拒绝，不能降级为丢 Group 的
  普通 Paste。下一阶段继续沿审计清单补原版编辑闭环与这些明确的 CREATE 能力边界。
