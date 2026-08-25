# ADR-0393：选区寄存器页面作用域重置

- 状态：已接受（2026-08-25）
- 场景：Harmony 的选区颜色、宽度和样式上下文保存在 NotePage，但翻页只清空 SelectionTool 状态；
  旧页寄存器可能污染下一页的第一次样式命令或 UI 回显。
- 决策：将 selection-controls 回调扩展为 nullable 寄存器更新。翻页成功且取消选区后发送显式 reset；
  正常选中仍按首个合格笔迹提供完整上下文，但 null 字段不再覆盖当前值。
- 结果：选区寄存器与页面作用域一致，跨页无 stale command source；同一页混合选择和铅笔 Taper 门禁不变。
