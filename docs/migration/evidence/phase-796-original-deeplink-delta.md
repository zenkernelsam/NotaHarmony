# Phase 796 证据：原版 1.4.2 深链与 intent-filter 差

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——manifest 深链面收尾。
证据源：两版 `resources/AndroidManifest.xml` intent-filter diff、
`note/src/main/module.json5`、`DeepLinkIngress.ets`。
Replay：`docs/migration/replays/d02-original-deeplink-delta.mjs`
ADR：`ADR-0740-original-deeplink-delta.md`

## 1. 深链 intent-filter 差（autoVerify, notability.com）

1.0.3 既有：`/authlink`、`/app/note`（pathPrefix）+
`/event/learn-from-home`、`/event/plus25`（精确路径）。

1.4.2 新增：
- `pathPrefix="/gallery"`——画廊分享深链（774 簇入口）。
- `path="/event/planner2627"` + `path="/event/planner2627/"`
  ——学术计划本营销活动深链（782/792 簇入口）。

同一 filter 内，宿主 notability.com 与 *.notability.com，
http/https 双 scheme，BROWSABLE+DEFAULT+autoVerify。

## 2. 其余 intent-filter 面（两版一致或已登记）

- `IMAGE_CAPTURE_SECURE`（760 已登记，锁屏相机）。
- PDF VIEW(content/file)/SEND、`CREATE_NOTE` action：
  两版一致。
- `msauth://com.gingerlabs.notability`（MicrosoftSignInActivity，
  MSAL SSO 回跳）：两版一致。
- `HwrEngineService` 声明：768 本地 HWR 服务佐证。
- `RecordingForegroundService`（microphone 前台服务）：
  两版一致。
- meta-data 47→48：vendor 初始化器差（无行为面）。

## 3. Harmony 侧对照

`DeepLinkIngress.ets` 已实现 notability.com http/https +
`/app/note` 链路；`/authlink` 与 `/event/*` 营销族已登记
fail-closed（后端校验/营销落地）。本阶段增量：
`/gallery` pathPrefix 与 `/event/planner2627` 具体路径值——
语义归 774（画廊）与 782（计划本营销）两簇。

## 4. 结论

manifest 深链面全量归属；新增两条深链均指向已登记簇
（画廊社交/计划本营销），无独立新功能。
