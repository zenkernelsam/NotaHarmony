# Phase 742 — 原版 Zoom View 旗标判定更正（ADR-0690）

日期：2026-09-25

## 结论

复核 ADR-0644 时发现其 ZOOM 项判定与打包证据矛盾：原版 1.0.3 的
`androidZoomView` 远程配置**打包默认值为 `true`**，且 ZOOM_VIEW 属
PRODUCTION 级旗标（`lc4.a` ordinal-3 分支直接读远程配置值），本地无覆盖、
非 JUnit 运行时、PRODUCTION 构建三条件在出货包中恒成立 —— 因此 `s01.a0`
默认保留 `a6f.U`(ZOOM) 工具，湿墨 Zoom View 为 1.0.3 **默认开启的在线功能**，
而非“旗标未开”。本阶段更正登记：ZOOM 由“旗标对等缺省”改登记为
**延迟移植缺口（port-deferred gap）**；同 ADR 内 POINTER/RULER/view-only
三项判定复核后维持不变。

## 判定链证据

1. `ac4.java`：`e0 = ac4("ZOOM_VIEW",19,zb4.L,ztb.c)`；`zb4.L`=PRODUCTION，
   `ztb.c`="androidZoomView"（lrb 布尔键）。
2. `lc4.a` ordinal-3（PRODUCTION）分支 → `trb.e(ac4Var.J)` →
   `oh4.h.b` → `sh4.a()`。
3. `core_remoteconfig__remote_config_defaults.xml`：
   `androidZoomView=true`；对照 `androidNoteTapeTool=true`（REVIEW/胶带
   默认可见且已移植，判定路径完全一致）。
4. 原版表面：`ww2` 控制条（back/forward/return/close 四键 + 六个
   `zoom_view_*` 无障碍标签）、`g0j` 前移区把手（`zoom_advance_tab` +
   `zq4` move 拖动）、`vgg`/`ggg` 状态机。
5. Harmony 现状：工具箱 13 槽无 ZOOM 位，无 zoom_view/wetink 实现。

## 变更

- `docs/migration/adr/ADR-0690-original-zoom-view-flag-correction.md`：新增，
  更正 ADR-0644 ZOOM 项，登记为延迟移植缺口并列明后续实施面。
- `docs/migration/adr/ADR-0644-original-pointer-zoom-presence-failclosed.md`：
  头部加更正指引（POINTER/RULER/view-only 原判维持）。
- `docs/migration/evidence/original-zoom-view-flag-correction-jadx-2026-09-25.md`：
  新增，旗标求值链 + 枚举位 + 表面 + Harmony 现状逐条证据。
- `docs/migration/replays/d02-original-zoom-view-flag-correction.mjs`：新增，
  26 断言（旗标定义链 / 打包默认 / 工具过滤门 / Zoom View 表面 /
  Harmony absence / ADR 更正登记）。
- `修复总纲.md`、`修复总纲2.md`、`修复进展-2026-08-09.md`：登记本阶段。

## 无源码行为变更

本阶段仅更正登记与证据；Harmony 工具箱缺 ZOOM 位的实现状态不变。
后续若实施 Zoom View，需覆盖工具箱 ZOOM 位、`ww2` 四键控制条、`g0j`
前移区把手、`vgg`/`ggg` 状态机对应的放大书写条与自动前移语义（另立阶段）。

## 验证

- 专项 Replay：`D02_ORIGINAL_ZOOM_VIEW_FLAG_CORRECTION_REPLAY_OK TOTAL=26 FAILED=0`。
- 全量 Desktop Replay：见提交信息。
- ArkTS 静态检查与 `note@ohosTest`/`note@default` 双 clean HAP：通过。
- 未启动模拟器/真机（按规约）。
