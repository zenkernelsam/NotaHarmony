# ADR-1363：Manifest + 残余资源轴收口裁决

- 状态：Accepted
- 关联：ADR-0632/0634/0635/0636/0680（widgets）、ADR-0645（selection
  菜单/MyScript iink 边界）、ADR-1341（NoteCoverSheet）、
  ADR-1362（strings.xml 前缀扫描收口）、
  evidence `phase-1428-manifest-residual-axes.md`

## 背景

继 ADR-1362 收口 `strings.xml` 后，本裁决覆盖 `AndroidManifest.xml`
组件清单与 `res/xml|raw|font|anim|animator|interpolator|menu|layout|
color|integers|dimens` 残余资源轴。

## 决定

### 已移植/平台等价

- 录音前台保活：`RecordingForegroundService`/`AudioCaptureService` →
  `backgroundTaskManager` 连续任务（`OriginalRecordingSourceBackend`）。
- `ExportFileProvider`：Harmony 分享经系统通路，无 FileProvider 需求。
- `AppUpgradeReceiver`：仅触发 ART baseline profile 写入
  （`zv` case1 → `tid.b` profileinstaller），无应用数据迁移工作；
  HarmonyOS 自有 AOT，无等价需求 → 平台边界，非缺口。

### fail-closed

- `ApiGatedFirebaseInitProvider`、`core_remoteconfig` 缺省表：GMS。
- `HwrEngineService`：MyScript iink 绑定服务，同 ADR-0645 边界。
- Widget providers + `app_widgets__*_widget_info.xml`：ADR-0632 系列。
- `inky_2026_v32.riv` + `inky_mode_enabled`：AI 模式动效+远端服务。
- `ui_designsystem__anim_*`/`learn_confetti` Rive 动效：Learn/启动页
  面（有 static_* 回退），Learn 后端门禁。
- `pdfnet.res`/`pdftron_*.plugin`：PDFTron 私有引擎资源。
- `ayp_youtube_player.html`：vendored YouTube iframe。
- `res/font` 品牌字体族：许可专有 UI 字体，Harmony 用系统字体。
- vendored 族：Material/S Pen `qt_*`/`mini_pen_*`/`spen_recoil_*`/
  compat/notification/m3c/base_dialog 常量与动画。

### `feature_note__*` 残余复核

改名键全数移植；fail-closed 面 = gif_picker(Klipy)、
youtube/transcripts、version_history/presence/view_only/finish_notes、
hwr_panel（iink）、inky、quick_tool（S Pen）、download_failed/
access_denied（同步）、disconnect_stylus（BT）。

## 结论

Manifest 与残余资源轴全部裁决完毕：无新增可移植缺口。后续 Phase
转向行为/交互层的剩余差异复核。

## 验证

`d02-original-manifest-residual-sweep.mjs` 11 项断言全绿；
全量基线与双构建见 Phase 1428 报告。
