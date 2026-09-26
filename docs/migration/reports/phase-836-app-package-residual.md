# Phase 836 — `app/` 包残余面闭合

## 范围

`com/gingerlabs/notability/app/` 下未审计项：initializers/、
demo/、widget config 基类。

## 原版发现

### androidx.startup Initializer 链（1.0.3 已存在）

- `LoggingInitializer`（deps=4 个 DataStore initializer）：
  装设 UncaughtExceptionHandler **吞 GMS 证书
  SecurityException**（已知 vendor bug 规避），其余透传；
- `AppStartupInitializer`：deps=[LoggingInitializer]——
  两级启动排序。

### Widget 配置基类 `a2k`

`abstract int h()` 返回登录要求字符串 id；onCreate 登录
门控（未登录 finish）。子类：
- `FolderNotesConfigActivity`（15 行壳）→ folder_picker 文案；
- `NoteThumbnailConfigActivity`（309 行 picker sheet）→
  note_picker 文案 + title/search_hint/no_notes/unfiled 四面。

`app/demo/DemoResetWorker` 确认为应用级包（823 已登记）。

## Harmony 侧

启动排序由 ability onCreate 显式编排；GMS 吞并不移植；
卡片配置页自鉴权（openFormEditAbility）。

## 验证

- 新 Replay `d02-app-package-residual.mjs`：**12/12**
  （initializer 依赖图×3、GMS 吞并、a2k 门控、两 config
  文案、picker sheet 面、1.0.3 存续）。
- ADR-0780。**`app/` 包全面闭合。**
