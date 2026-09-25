# Phase 710：`ac4` 远程旗标尾项 fail-closed 总登记（审计收官）

完成原版 `ac4` 70 项远程旗标的全量消费方审计（`lc4.a(ac4.*)`
全注册表→全部 JADX 引用点）。本阶段登记剩余未覆盖尾项，
`ac4` 审计自此闭合。

## 尾项分类

### A 类：远程门控可选行/项（旗标关闭=不出现=Harmony 现状）

- `h0` SECONDARY_TOOLS(22)：已连接笔二级工具条（`ch2:94`/
  `ys2:1099` +48dp 笔状态槽）——同 SPen 手写笔远程面。
- `Q0` NAV_PAGES(59)：`s3d` 新设置导航结构；关闭=旧平铺
  列表=Harmony 现状。
- `n0` MANAGE_SUBSCRIPTION(28)：`s3d`/`x97` 订阅行。
- `S0`(61)/`J0`(52)：`od` ⋮ 菜单设置链接与文档默认分区。
- `P0`(58)/`r0`(33)：`ks` 手写绘图附加行/识别开关行；
  `x90:10556` 工具行识别图标。
- `R0`(60)/`U0`(63)/`T0`(62)：newsletter/诊断/pro info 设置行。
- `V0`(64)：`fdi` 模板分区标签页变体（关闭=单列表）。
- `K0`(53)/`w0`(38)/`q0`(32)：库 Templates 项/内容管理器
  Create template/Copy note ID。
- `s0`(34)：调试菜单（内部）。

### B 类：订阅/后端/私有 API（结构性 fail-closed）

- `l0` NOTE_LIMIT(26)：`en9` 免费层 ≥5 篇上限（订阅档位依赖）。
- `m0` UNLOCKED(27)：`gti` KeyguardManager 设备锁态
  （Android-only API）。
- `j0` SIX_MONTHS(24)：`rt8` 订阅时长引导。
- `H0` ROOM_SEARCH(50)：`m60` DI Room 引擎选型（Harmony
  已有自有搜索）。
- `o0` PAYWALL_PROMO(30)：`tt8` 付费墙推广（订阅域外）。
- `X` COLLAB_RTL(12)：`kr8`/`rs3` 协作 CRDT RTL（协作面已
  fail-closed）。

### C 类：1.0.3 死旗标（零消费方）

`g0`/`G0`/`U`/`v0`/PLAY_LAUNCH_PROMO——声明未接线，无行为
差异。

## 已实现开态（不登记）

`V` ENTITY_GROUPS（selectionGroups/groupIds 已实现）、
`W` STROKE_STYLE（BrushStyle 按钮已实现）、`N0` NIGHT_MODE
（`note_view_night_mode` 行已实现）。

## 验证

- `d05-original-remote-flag-tail-fail-closed.mjs`（28 断言：
  全部消费方 pin + 死旗标零消费方验证 + Harmony 关闭态/
  开态核对 + ADR/证据）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
