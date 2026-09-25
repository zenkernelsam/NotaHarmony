# 原版 SPen Quick Tools — JADX 证据（2026-09-25，Phase 709）

## 旗标与可用性链

- `ac4.java:103-104`：`new ac4("SPEN_QUICK_TOOLS", 8, zb4Var,
  ttb.c, null)` → `ac4.T`（序号 8，PRODUCTION + 远端键）。
- `xod.java`：快捷工具可用性状态器——`a()` 中
  `te3.a() && lc4.a(ac4.T)` → `asd`→`ufb` 可用性流；
  无配对笔（`c == null`）时直接发 `FALSE`。
- `te3.a()`（`ra` case23，`ra.java:148-151`）：
  `svd.g0(Build.MANUFACTURER, "samsung") ||
   svd.g0(str8, "samsung electronics")`——**三星厂商门**。

## 弹出条件（`bq1.java:227-248`，TOOLBAR case5）

手写笔悬停/工具位坐标事件回调内：

```java
xodVar.a();                                   // 刷新可用性
r5f r5fVar = (r5f) i8fVar.m.getValue();       // 当前已连接笔
e31 e31VarA = r5fVar != null ? r5fVar.a() : null;
if (xod.b 为真 && r5fVar != null
    && w7b.b().contains(r5fVar.g())           // 已配对笔列表
    && e31VarA != null) {                     // 笔远程事件源
    // 快捷工具项列表 x6fVar.b.b → u5f.c
    asdVar.k(new u7b(x, y, r5fVar.g(), e31VarA.c,
                     w7b.a(items, r5fVar.g())));  // 弹出状态
}
```

- `a8b.java:18-25`：`xod` 注入工具栏 ViewModel，`xod.b` 与
  `i8fVar.m`（笔连接流）合并入 `O` 状态。
- `fn9.java:81/92`：DI 提供 `xod`/`a8b`。

## 字符串面

- `feature_note__cd_quick_tool_{color,eraser,highlighter,pen,
  pencil}`——快捷工具项无障碍描述（"Color"/"Eraser"/…）。

## Harmony 侧核对

- `note/src` 无 spen/quickTool/penRemote 实现；仅
  `cd_quick_tool_color` 串被色板按钮复用（ADR-0529）。
- Harmony 手写笔栈为 Pencil Kit，无 SPen 远程协议/厂商门。

## 结论

SPEN_QUICK_TOOLS = 三星厂商门 + SPen 远程 SDK + 远程旗标三重
依赖；Harmony 呈现旗标关闭态，按 ADR-0657 登记 fail-closed。
