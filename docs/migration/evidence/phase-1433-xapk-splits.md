# Phase 1433 — xapk 分包轴收口（+ P1429 贴纸投递方式更正）

## xapk 结构（Notability_1.4.2/*.xapk，23 项）

```
com.gingerlabs.notability.apk     base（无 lib/ —— natives 走 abi split）
config.<15 locale>.apk            ar/de/en/es/fr/hi/in/it/ja/ko/my/pt/ru/th/tr/vi/zh
config.xxhdpi.apk                 密度位图
config.arm64_v8a.apk              原生 .so
stickers.apk                      install-time asset pack
```

## 逐项裁决

### config.<locale> —— 仅 resources.arsc

每个 locale split 只含 `AndroidManifest.xml` + `resources.arsc` +
`stamp-cert-sha256`。arsc 是 base strings.xml 的翻译表，键集同源 ——
已由 strings 前缀扫描轴（P1427-1429）全域收口；Harmony `zh_CN` 资源表
已移植相应键。

### config.xxhdpi —— vendored + 平台边界

- `abc_*`/`notification_*`/`common_*`/`googleg_*`/`tw_widget_*`（约 45
  项）：Material/AppCompat/GMS/Samsung vendored。
- `app_widgets__widget_label_{note,recording}.png`：桌面 widget 标签图
  —— 随 widget 轴 ADR-0632 fail-closed。
- `feature_login__learn_{business,other}.webp`：登录页 Learn 营销图 —
  登录/订阅后端边界。
- `ui_designsystem__{academic_planner,six_months_plus}_onboarding.webp`：
  `lra.E0`/`F0` 两张 `s0c` 公告卡（标题/描述/图片三元组）的配图 ——
  "The 2026 Academic Planner is here"（模板推广）与 "6 months of Plus,
  on us"（订阅权益赠送）。经 `zb6`/`ec6` 公告管线、`adn.a` 分页卡渲
  染；`F0` 显式要求订阅后端态，`E0` 为一次性营销公告。Harmony 无订阅/
  公告系统 → fail-closed。

### config.arm64_v8a —— 25+ .so 全 vendored/平台原生

| so | 归属 | 裁决 |
|----|------|------|
| libMyScript{2D,Analyzer,Document,Engine,Gesture,Ink,MLOrt,Math,Shape,Text} | iink | ADR-0645 |
| libPDFNetC | Apryse | Harmony 自有 PDF 管线已移植 |
| libmlkit_google_ocr_pipeline | ML Kit GMS | vendored |
| libcrashlytics{,-common,-handler,-trampoline} | Firebase | GMS |
| librive-android | Rive | Inky AI 动效 fail-closed |
| libicing | AppSearch | vendored 搜索库 |
| libink | Google Ink | ADR-1327 |
| libdatastore_shared_counter / libc++_shared / libandroidx.graphics.path / libgraphics-core | androidx | vendored |
| libglmath | MicroTeX | Harmony 打包的是 glmath 字体/映射资产（rawfile/glmath），非 .so |

### stickers.apk —— install-time asset pack（更正 P1429）

manifest 字符串直证：`asset-pack`/`delivery`/`dist`/`fusing`/
`install-time`/`isFeatureSplit`/`module=stickers`。内含约 2900 个
`assets/sticker_<pack>/*.webp`（dwg.java 列出 39 个命名包）。
`pq3` 运行期经 `AssetPackManager.b("stickers")` 取包位 —— **贴纸内
容随安装分发**（install-time），CDN `…/stickers/1.1.0/<pack>.zip`
仅为 `StickerPackPrefetchWorker`/`DownloadWorker` 的增量预取。

**门禁不变**：`h35.z0`=STICKERS 以 `new rd5(null)` 构造，
`rd5.toString()`=InternalUserOnly；`h45.c` 的 rd5 分支要求
`z=ra1.a()`（内部构建）或 `a()<=INTERNAL_USER`——PRODUCTION 恒
false。全部消费点仅 `urf.java:411`（wqf.T SAVE_AS_STICKER）与
`d6b.java:1503`（托盘项 Function0）两处门控，生产均不可达。

**结论**：资产虽随装分发，UI 门禁仍是 InternalUserOnly；Harmony 亦无
Play asset-delivery 通路。维持 fail-closed，ADR-1364 措辞已更正
（"APK 无贴纸资产"→install-time asset pack + CDN 增量）。

## Harmony 验证

- 无贴纸托盘/选择器虚构；rawfile 无 `sticker_*`/`stickers` 目录。
- 无任何 vendored `.so` 打包。

## 验证

- Replay `d02-original-xapk-split-closure.mjs`：12/12。
- 全量基线 1284/1284；note@default / note@ohosTest BUILD SUCCESSFUL。
