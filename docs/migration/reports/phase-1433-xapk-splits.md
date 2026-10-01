# Phase 1433：xapk 分包轴收口报告（裁决阶段，零代码改动 + ADR-1364 更正）

- 日期：2026-08-09
- 状态：完成（裁决；Desktop Replay 13 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1433-xapk-splits.md`
- 决策：`docs/migration/adr/ADR-1368-xapk-split-closure.md`
- Replay：`docs/migration/replays/d02-original-xapk-split-closure.mjs`

## xapk 结构裁决（23 项）

- **config.\<locale\>**（15）：仅 `resources.arsc` 翻译表 —— 键集随
  strings 扫描轴已收口；zh_CN 已移植。
- **config.xxhdpi**：`abc_*`/`notification_*`/`googleg_*`/`tw_widget_*`
  vendored；`app_widgets__widget_label_*` 随 widget 轴（ADR-0632）；
  `feature_login__learn_*` 登录营销（后端）；`ui_designsystem__*
  _onboarding`（`lra.E0`/`F0` 公告卡——planner 推广 + Plus 权益赠送，
  `zb6`/`ec6`+`adn.a`）订阅/营销面 fail-closed。
- **config.arm64_v8a**：25+ `.so` 全 vendored/平台原生 —— MyScript
  iink（ADR-0645）、PDFNetC（Apryse）、MLKit OCR（GMS）、
  crashlytics、rive-android、icing、libink（ADR-1327）、androidx 族、
  `libglmath`（Harmony 打包 glmath 字体资产而非 .so）。不打包。
- **stickers.apk**：install-time Play asset pack（manifest 直证
  `asset-pack`/`install-time`/`isFeatureSplit`），`pq3` 经
  `AssetPackManager.b("stickers")` 取位——**更正 P1429**：贴纸内容随
  装分发，CDN `stickers/1.1.0/` 仅为 Prefetch/DownloadWorker 增量。
  门禁不变：`h35.z0`=`rd5` InternalUserOnly（urf:411+d6b:1503 生产恒
  false），Harmony 无 asset-delivery 通路 —— 维持 fail-closed，
  ADR-1364 措辞已更正。

## 验证

- Replay `d02-original-xapk-split-closure.mjs`：12/12。
- 全量基线 1284/1284；note@default / note@ohosTest BUILD SUCCESSFUL。
- APK 包体结构审计至此全部收口。
