# Phase 838 — 深链 data 面 + n() 配置流

## 范围

三版 manifest `<data>` 全量解析 + `MainActivity.n()` 语义补完
+ Harmony 深链声明对照。

## 原版发现

### URI 谱系

- 1.0.1：`/authlink`、`/app/note`、`/event/learn-from-home`；
- 1.0.3：+`/event/plus25`；
- **1.4.2：+`/event/planner2627` + `/gallery`**（画廊簇同期）。

其余：`content`/`file` 附件、`application/pdf` MIME、
`msauth` MSAL 回跳；host=notability.com + `*.notability.com`。

### `n(configuration)` 补完

configChanges 处理 = 把 (Configuration + windowBounds) 推入
`ui9.c` 流——自适应布局事件源；`onTopResumedActivityChanged`
多窗置顶复走此。

## Harmony 侧

- uris 仅声明 `app/note`；`/gallery`/`/authlink`/`/event/*`
  fail-closed 登记（通配子域不支持）；
- `DeepLinkIngress` 注释漏 `/gallery`+`planner2627`——已修正；
- `onConfigurationUpdate`+ArkUI 自适应承担配置流。

## 验证

- 新 Replay `d02-deep-link-data.mjs`：**13/13**（三版谱系、
  host/scheme/MIME、n() 流断言×3、Harmony 声明+注释修正）。
- ADR-0782。
