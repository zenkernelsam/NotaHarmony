# ADR-1368：xapk 分包轴收口裁决（+ ADR-1364 贴纸投递更正）

- 状态：Accepted
- 关联：ADR-1364（贴纸门禁裁决——投递方式措辞更正）、ADR-0645
  （iink 边界）、ADR-1327（Google Ink）、ADR-0632（widget）、
  evidence `phase-1433-xapk-splits.md`、
  fixture `d02-original-xapk-split-closure.mjs`

## 背景

1.4.2 发行形态为 xapk（23 项）：base APK + 15 locale config +
xxhdpi config + arm64_v8a config + stickers 分包。此为 APK 包体最
后一个未审计轴。

## 决定

### config.<locale>（15 个）

仅 `resources.arsc` 翻译表 —— 键集与 base strings 同源，随字符串扫
描轴收口；Harmony `zh_CN` 已对应。

### config.xxhdpi

- vendored：`abc_*`/`notification_*`/`common_*`/`googleg_*`/
  `tw_widget_*`。
- `app_widgets__widget_label_{note,recording}.png` → widget 轴
  （ADR-0632）。
- `feature_login__learn_business.webp`/`feature_login__learn_other.webp`
  → 登录营销（后端边界）。
- `ui_designsystem__academic_planner_onboarding.webp` 与
  `ui_designsystem__six_months_plus_onboarding.webp`
  → `lra.E0`/`F0` `s0c` 公告卡（planner 推广 + "6 months of Plus"
  订阅权益），`zb6`/`ec6` 公告管线 + `adn.a` 分页卡 —— 订阅/营销面
  fail-closed。

### config.arm64_v8a

25+ `.so` 全为 vendored/平台原生：MyScript iink×9（ADR-0645）、
`libPDFNetC`（Apryse，Harmony 自有 PDF 管线）、
`libmlkit_google_ocr_pipeline`（GMS）、`libcrashlytics*`（GMS）、
`librive-android`（Inky AI 动效）、`libicing`（AppSearch）、
`libink`（ADR-1327）、`libdatastore_shared_counter`/`libc++_shared`/
`libandroidx.graphics.path`/`libgraphics-core`（androidx）、
`libglmath`（MicroTeX —— Harmony 打包 rawfile/glmath 字体资产非 .so）。
均不打包。

### stickers.apk —— install-time asset pack（更正 ADR-1364）

manifest 直证 `asset-pack`/`install-time`/`isFeatureSplit`/
`module=stickers`；内含 `assets/sticker_<pack>/*.webp` 约 2900 项
（`dwg` 39 命名包），`pq3` 经 `AssetPackManager.b("stickers")` 取位。
ADR-1364 原措辞"APK 无贴纸资产、纯 CDN"更正为：**贴纸内容随
install-time asset pack 分发**，CDN `stickers/1.1.0/` 仅为增量预取。
门禁结论不变：`h35.z0`=`rd5`（InternalUserOnly），`urf:411`+
`d6b:1503` 两处门控生产恒 false；Harmony 无 Play asset-delivery 通
路 —— 不虚构托盘/选择器/资源，维持 fail-closed。

## 后果

- xapk 分包轴全域收口：locale 翻译表已覆盖、xxhdpi vendored/营销/
  widget 边界、arm64 vendored natives、stickers asset pack
  fail-closed（更正登记）。
- APK 包体结构审计至此全部收口。

## 验证

- `d02-original-xapk-split-closure.mjs` 12/12；全量基线 1284/1284；
  note@default / note@ohosTest BUILD SUCCESSFUL。
