# ADR-0392：选区样式工具栏上下文绑定

- 状态：已接受（2026-08-25）
- 场景：1.0.3 `dhb.java` 从选中 Ink 的 `t16` ordinal 反向映射为 `y31` 样式枚举，作为选区样式控件当前值。
  Harmony 只回传颜色、宽度、宽度和 Taper 可用性，导致选中已有笔迹后样式按钮没有当前态。
- 决策：复用 selection-controls 单一回调，在颜色/宽度同一确定性策略下携带第一个非 partial 笔迹的 `inkStyle`；
  新增 `t16 → y31` 等价反向映射并在 NotePage/Toolbar 绑定。不改变持久化协议或修改历史语义。
- 结果：选区样式按钮回显 MONO/Taper/DASH/DOT；混合选择沿用首个合格笔迹决定颜色和宽度；铅笔上下文继续禁用 Taper。
