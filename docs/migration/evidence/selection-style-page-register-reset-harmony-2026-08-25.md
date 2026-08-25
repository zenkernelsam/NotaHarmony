# Harmony 证据：选区寄存器页面作用域重置

- 日期：2026-08-25
- 缺陷：翻页成功会执行 `selectionTool.deselect()` 并隐藏 overlay，但 NotePage 仍保留上一页选中的
  color/width/style。若下一页先修改笔刷寄存器再选择笔迹，旧页上下文可能被当作新页选中状态使用。
- 原版对照：1.0.3 `xsc.m()/s()/t()` 将 selection state 原子重置为空态；`xsc.v()` 在跨页选择时显式失败。
  选区命令上下文因此不跨页延续。
- 修复：selection-controls 回调改为 nullable。正常选择只覆盖有值的寄存器；页面加载完成并取消选区后，
  Canvas 发送 `(null,null,0.5,30,true,null)`，把 style/color/width 恢复为默认、Taper 可用。
- 边界：不改持久化协议；不改变同一页内“第一个非 partial 笔迹”策略；加载失败回滚到原页时不额外重置，
  以保留该页当前上下文。
