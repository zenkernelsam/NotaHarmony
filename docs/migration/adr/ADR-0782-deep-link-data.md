# ADR-0782 — 深链 `<data>` 面归档

- 状态：已接受
- 证据：`docs/migration/evidence/phase-838-deep-link-data.md`
- 回放：`docs/migration/replays/d02-deep-link-data.mjs`（13/13）

## 决定

1. `/gallery` 与 `/event/planner2627`（1.4.2 新增）补登记为
   fail-closed——Harmony uris 未声明且子域通配不支持；
   `DeepLinkIngress` 注释已修正为完整清单。
2. `msauth`/`content`/`file`/`application/pdf` 面归档：
   pdf file 已声明，msauth 无对应（MSAL 专属）。
3. `MainActivity.n()` = (Configuration+WindowBounds)→`mi9`
   流——自适应布局事件源；Harmony `onConfigurationUpdate`
   + ArkUI 自适应承担，语义对齐。

## 后果

深链面按版本谱系闭合（1.0.1→1.4.2 三次增量全归因）；
MainActivity configChanges 实际语义补完。
