# 原版 `ac4` 远程旗标尾项 — JADX 证据（2026-09-25，Phase 710）

## 旗标→字段→消费方全量对照（尾项）

`ac4.java` 注册表（`new ac4("NAME", idx, zb4Var, key, …)`）→
静态字段：`L`-`Z`（0-14）、`a0`-`o0`（15-30）、`p0`-`V0`
（31-64）、`W0`/`X0`（数组/迭代器）。TEST_*（65-69）为测试
旗标。

### A 类：可选行/项（旗标关闭=不出现）

- `ac4.h0` SECONDARY_TOOLS(22)：`ch2.java:94` 非笔工具分支
  `o22Var.invoke` 需旗标开；`ys2.java:1099` 旗标开加工具条
  高度 `48.0f`×已连接笔状态槽（`r5fVar5/7`）——手写笔远程
  面延伸。
- `ac4.Q0` NAV_PAGES(59)：`s3d.java:17` 旗标开返回新导航列表
  （+connected_services；AI 行移出 Learn 门控），关闭=旧平铺
  列表——Harmony 设置=平铺。
- `ac4.n0` MANAGE_SUBSCRIPTION(28)：`s3d.java:59` 过滤
  manage_subscription 行。
- `ac4.S0` NOTE_EDITOR(61)/`ac4.J0` DOC_DEFAULTS(52)：
  `od.java:64-88` ⋮ 菜单分区（`qnh.a/c/f`）与设置链接
  （`qnh.i/l`）。
- `ac4.P0` HANDWRITING_DRAWING(58)：`ks.java:109-117` 附加行
  `pb5`+`sih.f`、`ob5` case6。
- `ac4.r0` RECOGNITION_TOGGLE(33)：`ks.java:118` 识别开关行
  `rb5`（`ub5.e` 状态 + Switch）；`x90.java:10556` 工具行识别
  图标 `m18.i(function1,…)`。
- `ac4.R0` NEWSLETTER(60)/`ac4.U0` DIAGNOSTICS(63)：
  `q0.java:51` 设置表可选行 `o22(t0)`/`jeh.f`。
- `ac4.T0` PRO_INFO(62)：`x22.java:344` pro info 行（
  `feature_settings__pro_info_text` 上方）。
- `ac4.N0` NIGHT_MODE(56)：`q0.java:164` 设置项列表中
  `j60` case6 行——Harmony `SettingsPage.ets:837`
  `note_view_night_mode` 已实现等价开态。
- `ac4.V0` SECTION_PICKER(64)：`fdi.java:210` 旗标开按 `lge`
  枚举渲染双标签页变体，关闭=单列表 `th(o22VarI2)`。
- `ac4.K0` ADD_NOTE_MENU(53)：`cd.java:58` 库新建菜单
  Templates 项（`feature_library__templates`）。
- `ac4.w0` CREATE_TEMPLATE(38)：`n9j.java:2055` 内容管理器
  "Create template"（`feature_note__content_manager_create_
  template`）。
- `ac4.q0` COPY_NOTE_ID(32)：`d5j.java:242` 库笔记菜单
  "Copy note ID"（`feature_library__copy_note_id`）。
- `ac4.s0` DEBUG_MENU(34)：`x90.java:10391` 调试功能菜单分支。

### B 类：订阅/后端/私有 API

- `ac4.l0` NOTE_LIMIT(26)：`en9.java:21` 旗标+`v2e.a!=vsf.Q`
  +非 `v6` → `i>=5` 时 `a89`/`d89`（免费层上限态）。
- `ac4.m0` UNLOCKED(27)：`gti.java:25` `KeyguardManager`
  系统服务取设备锁态——Android-only API。
- `ac4.j0` SIX_MONTHS(24)：`rt8.java:24` 订阅时长/档位判定
  引导（`i0eVar.e()==y3e.M && v2e.a==vsf.N`）。
- `ac4.H0` ROOM_SEARCH(50)：`m60.java:160` DI 选择 `clc`
  实现（Room 引擎 vs 旧实现）。
- `ac4.o0` PAYWALL_PROMO(30)：`tt8.java:214` 付费墙推广
  收集流。
- `ac4.X` COLLAB_RTL(12)：`kr8.java:250`/`rs3.java:200`
  协作 CRDT `uub.d`→`jtc`→`fke` RTL 状态传播。

### C 类：死旗标（grep `ac4.<field>` 零消费方）

`g0`(21)、`G0`(48)、`U`(9)、`v0`(37)、PLAY_LAUNCH_PROMO(29，
无字段赋值)。

## Harmony 侧核对

- 设置面：`SettingsPage.ets` 平铺列表（Appearance/Note
  Editor/Language/…+Default Template/Recently Deleted/Backup），
  无 account/subscription/connected_services/ai_customization/
  newsletter/diagnostics/pro_info 行——旗标关闭态。
- 库/笔记菜单：无 Templates 项、无 Create template、无
  Copy note ID、无调试菜单——旗标关闭态。
- 已实现旗标开态：`selectionGroups`/`groupIds`（实体组）、
  `style_dash` 等 BrushStyle 按钮（笔型样式）、
  `note_view_night_mode` 行。

## 结论

尾项全部旗标：旗标关闭呈现=Harmony 现状，或依赖域外/私有
能力，或 1.0.3 内未接线。按 ADR-0658 登记；`ac4` 审计闭合。
