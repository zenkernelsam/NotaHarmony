# ADR-0112: 原版 Group Paste 运行时接线与剪贴板图

## 背景

原版 `lg2` 调用 `u5j.c()` 复制选中实体，随后筛出 `CREATE_GROUP` 操作并恢复顶层 Group 选择。此前
HarmonyOS 剪贴板只保存 `containsOriginalGroups` 布尔值，无法重建 nested Group；UI 只能走普通
`ADD_ELEMENTS`，会永久扁平化 Group。Phase 133/134 已提供原子 CREATE 与复合 Undo/Redo，但尚未由
运行时 Paste 调用。

## 决策

- `StrokeClipboard.copy()` 从所选 top Groups 递归保存完整子图，拒绝环、缺失成员、重复成员和多父成员，
  并以 child-before-parent 顺序深拷贝。失败不得覆盖已有剪贴板。
- Group Paste 使用只读 preview。preview 复用下一个 Paste 序号计算偏移，但不修改 `pasteCount`；只有
  持久事务成功后 `commitPreparedPaste()` 才消费序号，因此失败重试仍得到相同偏移。
- Ink/Shape 的源 transform 与本次 Paste 位移在编码前共同物化到 CREATE 几何。移动、旋转和等比缩放
  同步作用于点、宽度、Pencil reference/splat；剪切或非等比矩阵因无法由现有 CREATE 精确保真而明确
  拒绝，不能静默清零 transform。
- UI 先构造并调用 `validateOriginalClipboardPastePlan()`，再调用 Phase 133 的
  `commitOriginalClipboardPaste()`。事务成功前不得改变画布、Group、history 或 Paste 序号。
- 成功后使用返回的真实 NCP1 `Op` 推入 `ORIGINAL_CLIPBOARD_PASTE` action，安装完整页面层序和完整
  active Groups，并选择返回的新 top Groups。若异步期间页面已切换，只更新全笔记 history，不污染
  当前页面画布。
- `OriginalClipboardPastePersistenceResult.groups` 返回全部 active Groups，而非仅本次创建的 Groups；
  否则 UI 安装结果会丢掉目标页原有 Group 状态。

## 后果

Ink/Shape/Text 组成的原版 Group 现可从 Copy 到 Paste、持久化、顶层选择和 Undo/Redo 保持一个原子用户
动作。Image/Math、Styled Text、带 RichText 的 Shape 仍受 Phase 133 的显式 CREATE 能力门禁，不会退回
普通 Paste 后悄悄扁平化；后续应在原版 CREATE_BLOCK/文本样式生产链具备后扩展同一事务，而不是另建
不兼容路径。
