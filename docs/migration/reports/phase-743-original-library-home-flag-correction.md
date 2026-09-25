# Phase 743 — 原版 LIBRARY_HOME 旗标判定更正 + 远程默认值全量扫描收官（ADR-0691）

日期：2026-09-25

## 结论

继 Phase 742 更正 ZOOM_VIEW 判定后，对 `ac4` 70 项旗标的远程
配置打包默认值做全量交叉扫描（51 键），发现同一判定错误的
最后一处：`LIBRARY_HOME`（`ac4.F0`）打包默认
`androidLibraryHome=true` —— 1.0.3 原版资料库导航**默认含
Home 分区**，ADR-0655 的“旗标关闭态=Harmony 现状”判定有误。
本阶段更正为**延迟移植缺口**；其中 `home_study_up_next` 子区
依赖 Learn 后端，维持 ADR-0652 fail-closed。

## 判定链证据

- `ac4.java:182`：`F0 = ac4("LIBRARY_HOME",47,zb4.L,tsb.c)`，
  PRODUCTION 级旗标；`tsb.c` = `"androidLibraryHome"`。
- `lc4.a` ordinal-3（PRODUCTION）→ `trb.e(tsb.c)` → `sh4.a()`
  → 打包默认 `true`。
- 消费方：`ajh.java:335` 门控导航 `feature_library__home` 项插入；
  `va7:30`/`wa7:118` 门控分区图标（`tnc.a`）；`ksh` 组合族渲染
  Home 内容（CTA 双卡、favorite/recent 区、study-up-next）。

## 51 键扫描分类（详见证据文档）

- 默认 true 且已移植：PENCIL、SNAP_TO_GRID、DESELECT_MODE、
  STROKE_STYLE、PARTIAL_ERASER、LIBRARY_DOC_SCAN、NOTE_TAPE_TOOL、
  ENTITY_GROUPS（uw2/vo2/xtc 组扩展 → OriginalGroupSelection/
  GroupLayering）、SHAPE_EDIT_SNAPPING（avc 形状会话 →
  OriginalSnapGuides）。
- 默认 true 且有效 fail-closed（服务端/供应商依赖）：VIEW_ONLY、
  MULTIPLAYER_PRESENCE、VERSION_HISTORY、SPEN_QUICK_TOOLS、
  COLLAB_RTL_TEXT、SHOW_TRANSCRIPTS、LEARN 族五键、
  SIX_MONTHS_PLUS_ONBOARDING、LAUNCH_PAYWALL_PROMO、
  SINGULAR_ATTRIBUTION、OpenTelemetry；AUDIO_INK_SYNC（h3
  tap 路径）属 ADR-0068/0069 已登记的独立契约。
- 默认 true 判定更正：ZOOM_VIEW（ADR-0690）、LIBRARY_HOME（本
  阶段）——全部两处已更正完毕。
- 默认 false/非布尔：维持旗标关闭态登记不变。

## 变更

- `docs/migration/adr/ADR-0691-original-library-home-flag-correction.md`：新增。
- `docs/migration/adr/ADR-0655-original-library-home-failclosed.md`：
  头部加更正指引。
- `docs/migration/evidence/original-library-home-flag-correction-jadx-2026-09-25.md`：
  新增，含求值链 + 51 键扫描分类表。
- `docs/migration/replays/d02-original-library-home-flag-correction.mjs`：新增，
  17 断言（旗标链 / 默认值 / 消费方 / 同扫描复核 / Harmony absence /
  更正登记）。
- `修复总纲.md`、`修复总纲2.md`、`修复进展-2026-08-09.md`、
  `真机验收清单-2026-09-22.md`（R-47）：登记本阶段。

## 无源码行为变更

本阶段仅更正登记与证据；Home 分区继续缺省，理由更正为延迟移植。
后续若实施需另立阶段：导航 home 项 + CTA 双卡 + favorite/recent
区可移植，study-up-next 区维持 Learn fail-closed。

## 验证

- 专项 Replay：`D02_ORIGINAL_LIBRARY_HOME_FLAG_CORRECTION_REPLAY_OK TOTAL=17 FAILED=0`。
- 全量 Desktop Replay：见提交信息。
- `note@ohosTest`/`note@default` 双 clean HAP：通过。
- 未启动模拟器/真机（按规约）。
