# Phase 709：原版 SPen Quick Tools 快捷工具 fail-closed 登记

`ac4` 旗标审计继续：`SPEN_QUICK_TOOLS`（`ac4.T`，序号 8）为
未登记的三星手写笔快捷工具面。

## 原版证据链

- `xod.a()`：`te3.a() && lc4.a(ac4.T)` → `ufb` 可用性流；
  无配对笔时直接 `FALSE`。
- `te3.a()`（`ra` case23）：`Build.MANUFACTURER` 含
  "samsung"/"samsung electronics"——**三星厂商门**。
- `bq1`（TOOLBAR case5）：悬停/工具位事件 → `xod.b` 真 +
  `w7b.b()` 配对笔列表包含 `r5fVar.g()` + `e31` 远程事件源
  非空 → 发射 `u7b(x,y,stylusId,e31VarA.c,items)` 弹出状态；
  工具项为笔/铅笔/荧光笔/橡皮/颜色（`cd_quick_tool_*`）。
- `a8b`/`fn9`：DI 注入工具栏 ViewModel。

## 决定

- 三重依赖：三星厂商设备 + SPen 远程 SDK（蓝牙笔按键/悬空
  协议）+ 远程旗标；Harmony 手写笔栈（Pencil Kit）无对应
  远程事件协议，厂商门恒假——按结构性 fail-closed 登记
  （`ADR-0657`）。
- Harmony 呈现旗标关闭态：无快捷工具弹出、无笔按键监听。
- `cd_quick_tool_color` 串已被色板按钮复用（ADR-0529），
  与快捷工具面无关联。

## 验证

- `d05-original-spen-quick-tools-fail-closed.mjs`（17 断言：
  旗标链/三星厂商门/u7b 弹出条件/字符串面/Harmony 无实现/
  ADR+证据）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
