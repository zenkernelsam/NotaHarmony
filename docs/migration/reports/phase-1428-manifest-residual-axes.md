# Phase 1428：Manifest + 残余资源轴收口报告（裁决阶段，零代码改动）

- 日期：2026-10-01
- 状态：完成（裁决阶段；Desktop Replay 11 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1428-manifest-residual-axes.md`
- 决策：`docs/migration/adr/ADR-1363-manifest-residual-axes.md`
- Replay：`docs/migration/replays/d02-original-manifest-residual-sweep.mjs`

## 目标

继 Phase 1427 收口 `strings.xml` 后，逐轴裁决 `AndroidManifest.xml`
组件清单与 `res/xml|raw|font|anim|animator|interpolator|menu|layout|
color|integers|dimens` 残余面。

## 裁决结果

### 已移植/平台等价

- 录音前台服务 → `backgroundTaskManager` 连续任务（已移植）。
- `ExportFileProvider` → Harmony 系统分享通路。
- `AppUpgradeReceiver` → 仅 ART baseline profile 写入，平台边界。
- 选择菜单全表（含 z-order/group/lock）已移植（ADR-0645）。
- `feature_note__*` 残余改名键全数覆盖（content_manager 页操作、
  jump_to、math_editor、empty_note、cropping、note_deleted→uc9、
  phone_title 行内重命名等）。

### fail-closed

- GMS/Firebase/Play assetpacks/WorkManager/MLKit/Room vendored 组件。
- MyScript `HwrEngineService` + `hwr_panel_*`（ADR-0645 同界）。
- Inky AI 动效 + Learn Rive 动效 + `learn_confetti`（后端+运行时）。
- PDFTron 私有资源、ayp YouTube iframe、品牌字体族。
- widgets（ADR-0632 系列）、S Pen `qt_*`/`mini_pen_*`/`spen_recoil_*`。
- `feature_note__*` fail-closed 面：gif_picker、youtube、
  version_history/presence/view_only/finish_notes、quick_tool、
  download_failed/access_denied、disconnect_stylus。

## 验证

- `d02-original-manifest-residual-sweep.mjs`：11/11 通过。
- 全量 Replay 基线、`note@default`、clean `note@ohosTest` 见提交说明。
