# Phase 738 — 原版库卡片日期格式对齐

- 日期：2026-09-25
- 类型：真实语义缺口修复（日期/时间格式化）
- ADR：ADR-0686
- 证据：`docs/migration/evidence/original-library-date-format-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-library-date-format.mjs`

## 背景

`LibraryPage.ets` 私有 `formatTime()` 以 `getMonth()/getDate()/getHours()/
getMinutes()` 手工拼接 `M/D H:MM`，用于库卡片副标题与扫描文档默认
标题。本阶段先把原版格式化路径钉死再动代码。

## 原版证据链

- `z5c.n(long)` = `h.a().format(Instant.ofEpochMilli(j2))`，
  `h` = `x2f(0)` = `DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)`
  —— locale-aware 中号日期，**无时间分量**。
- `nk9/ok9/mk9` 三处 `new w09(..., z5c.n(j89Var.m()), ...)` 将该
  字符串写入库卡片模型 `w09.e`（副标题）。
- `z5c.i`（SHORT 时间）消费于 `ar4` 录音分段行；`z5c.j`
  （MEDIUM 日期 + SHORT 时间）为已定义 datetime 格式化器。
- 已排除伪候选：`ypd`（Gson 序列化）、`zaj`（日志时间戳）、
  `kf`（HTTP-Date）、`wb0`（耗时）、`m56.c`（LONG 日期，另一域）。

## 变更

`note/src/main/ets/ui/library/LibraryPage.ets`：

- `formatTime` 拆为两个 formatter：
  - `formatLibraryDate` — `{ dateStyle: 'medium' }`，用于两处卡片
    副标题（`lastOpened`/`updatedAt` 选择不变）。
  - `formatLibraryDateTime` — `{ dateStyle: 'medium', timeStyle:
    'short' }`，用于 `scanned_document_title` 插值（`z5c.j` 等价物；
    原版 `%1$s` 实参在 GMS 扫描深链内不可直接读，见 ADR 偏差记录）。
- 两者带 try/catch 兜底，风格与 `RecordingPanel.ets` 一致。

可见差异：卡片副标题由 `1/5 14:30` 变为 `Jan 5, 2026`（en）/
`2026年1月5日`（zh_CN），与原版一致。

## 验证

- 聚焦 Replay `d02-original-library-date-format`：31 断言全绿
  （JADX 证据钉、Harmony 实现钉、文档钉、Intl 运行时等价模型）。
- 受影响既有 fixture `d02-original-library-doc-scan`：调用点 pin
  已随改名更新，回归全绿。
- 全量 Desktop Replay：622/622 全绿。
- ArkTS 构建：`note@default` assembleHap 成功；clean +
  `note@ohosTest` + `note@default` 双 HAP 静态构建成功（仅存量
  deprecated API 告警与未签名 HAP 告警）。

## 遗留

- `scanned_document_title` `%1$s` 原版实参格式不可直接读 —
  以 `z5c.j`（MEDIUM+SHORT）为有据最近邻并在 ADR 显式记录。
- 模拟器/真机/Hypium 未执行（按规则）。
