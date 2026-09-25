# 原版 Zoom View 旗标判定更正证据（JADX, decompiled_1.0.3）

日期：2026-09-25。来源：`decompiled_1.0.3` JADX 输出 + `resources/`。

## 结论

ADR-0644 将 ZOOM 工具登记为“远程旗标在 1.0.3 未开”，经复核**该判定与打包证据矛盾**：
`core_remoteconfig__remote_config_defaults.xml` 中 `androidZoomView` 默认值 = `true`，
且 ZOOM_VIEW 旗标属 PRODUCTION 级（其开关直接读远程配置值），因此在未抓取到服务端
覆盖值的情形下（含无 GMS 环境），1.0.3 原版工具箱**默认显示 Zoom 工具**，湿墨
Zoom View（放大书写条 + 自动前移区）是真实在线功能。Harmony 缺该工具构成
“已登记但需更正理由的移植缺口”：POINTER/RULER 两项判定仍然正确，仅 ZOOM 项需更正。

## 旗标求值链（逐步证据）

1. `ac4.java:124-125`：`ac4Var20 = new ac4("ZOOM_VIEW", 19, zb4Var, ztb.c, null)`，
   `e0 = ac4Var20`。第三参 `zb4Var` 为 `zb4.L`（`ac4.java:86`），即 PRODUCTION 级；
   第四参 `ztb.c` 为远程配置键。
2. `ztb.java`：`ztb extends lrb`，键名 `"androidZoomView"`，`toString` = "ZoomView"。
3. `zb4.java:14-21`：枚举序 `OFF(0)/DEBUG_ONLY(1)/INTERNAL_USERS_ONLY(2)/PRODUCTION(3)`；
   `lc4` 静态 `g = zb4.L`（本构建为 PRODUCTION）。
4. `lc4.a(ac4)`：先查本地覆盖表 `b`（仅 `w51.a()`=JUnit 运行时或 `c(ac4)`=INTERNAL/
   PRODUCTION 级可读），无覆盖则按 `ac4Var.I.ordinal()` 分支：
   - ordinal 3（PRODUCTION）：`ac4Var.J != null && !w51.a() && !b()` 时求值
     `trb.e(ac4Var.J)`（远程配置布尔）；`w51.a()`=`ra(8)` 仅探测 `org.junit.Test`，
     生产包恒 false；`b()`=`g<=INTERNAL` 在 PRODUCTION 恒 false → 进入远程配置分支。
5. `trb.e(orb)` → `oh4.h.b("androidZoomView")` → `sh4.a()`（lrb 分支返回 boolean）。
6. `resources/res/xml/core_remoteconfig__remote_config_defaults.xml:171-174`：
   `<key>androidZoomView</key><value>true</value>` —— 打包默认 = 开。

对照项：`ac4.t0` = NOTE_TAPE_TOOL，`btb.c` = `"androidNoteTapeTool"`，
同文件 303-306 行默认同样 `true` —— 胶带(REVIEW)工具默认可见且 Harmony 已移植，
与 ZOOM 的判定路径完全一致，佐证 ZOOM 同为默认可见。

## 工具箱过滤与枚举位

- `a6f.java`：PEN 0、PENCIL 1、HIGHLIGHTER 2、TEXT 3、ERASER 4、SELECT 5、
  MEDIA 6、RECORD 7、POINTER 8、LASER 9、REVIEW 10、RULER 11、ZOOM 12。
- `s01.a0(List)`（`s01.java:548-560`）：`a6f.T`(RULER) 无条件剔除；`a6f.U`(ZOOM)
  仅 `lc4.a(ac4.e0)` 为真时保留；`a6f.S`(REVIEW) 仅 `lc4.a(ac4.t0)` 为真时保留。
- `x82` case 12：`ui_tools__zoom` = "Zoom"（工具箱标签）。

## Zoom View 表面（原版）

- `ww2.java:408-413`：控制条四个按钮 —— back（`zoom_view_back_description`="Back"）、
  forward（"Forward"）、return（`ui_designsystem__zoom_return` 图标，
  "Return"）、close（"Close Zoom View"）。
- `g0j.java:69`：自动前移区调整把手（`zoom_advance_tab` 图标，
  `zoom_view_advance_region_description`="Adjust auto-advance area"）。
- `g0j.java:76+`：move（"Move Zoom View"）语义的拖动把手 `zq4`。
- `vgg.java`：Zoom View 状态管理器（位置/目标字段 `g`，注入 oze/fvb/uke/hnf/
  gc9/cga 六个协作件）；`ggg.java`：UI 状态（可见性 `a`、位置 `qeg`、目标 `cmb`、
  缩放浮点 `d`/`e`、标记 `f`）。
- 六个 `feature_note_wetink_ui__zoom_view_*` 字符串全部服务于该表面。

## Harmony 现状

- `a6f` 13 工具中 Harmony 工具箱无 ZOOM 位（`BrushTypes.ets`/`EditorViewModel.ets`
  留位注释指 ADR-0644）；无 `zoom_view`/`auto_advance`/`wetink` 实现。
- `ui_permissions__*` 6 字符串（相机/麦克风权限 rationale + Go to Settings）：
  Harmony 权限请求走系统对话框 + `permission_*` 自有文案，理由弹窗未逐项对应。

## 更正要点

ADR-0644 写作时据“旗标”字样推定 1.0.3 未开，未核对远程配置打包默认值。
更正后 ZOOM 项登记为：**原版默认开启的在线功能，Harmony 未移植** ——
属延迟移植缺口（port-deferred），非旗标对等。后续如需消除缺口，
应新开 Zoom View 实施阶段系列（放大书写条、自动前移区、前进/后退/return/close
控制条与工具箱 ZOOM 位），本阶段仅更正登记与证据。

> ⚠️ 已被 Phase 747–755 取代：Zoom View 完整移植（面板/5× 放大/
> 前移区持久化/源窗覆盖/边缘自滚/272dp 几何/停靠序交换/slide+fade
> 过渡），证据见 `phase-750/751/752/754/755-*` 与
> ADR-0700/0702/0703。
