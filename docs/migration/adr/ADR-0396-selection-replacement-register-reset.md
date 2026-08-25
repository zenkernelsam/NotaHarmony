# ADR-0396：选区替换寄存器重置

- 状态：已接受（2026-08-25）
- 场景：Phase 418 覆盖了权威退出，但照片插入、Math 插入、Group/Ungroup、粘贴和图片裁剪会先取消旧选区再选择新结果。
  若旧选区是笔迹而新选区不含 Ink，NotePage 的 selection color/width/style 会跨 selection identity 存活，工具栏回显
  与后续批量命令可能消费旧上下文。
- 决策：所有 selection replacement 在安装新 SelectionTool IDs 后、发布浮层前显式发布 nullable 寄存器默认态；
  随后 updateSelectionOverlay 只对实际选中的首个合格笔迹重新发布。该函数对空选区只隐藏浮层，不重复 reset，
  避免把临时空态误当作权威退出。
- 结果：寄存器生命周期绑定当前 selection identity。非 Ink 新选区回到默认工具栏；Ink 新选区按原有一致性策略重建；
  空态辅助调用不会覆盖权威退出后的寄存器。
