# ADR-0686：原版库卡片日期格式化对齐

- 状态：已接受
- 日期：2026-09-25
- 关联：`docs/migration/evidence/original-library-date-format-jadx-2026-09-25.md`、
  `docs/migration/replays/d02-original-library-date-format.mjs`、
  `docs/migration/reports/phase-738-original-library-date-format.md`

## 背景

`LibraryPage.ets` 原先的私有 `formatTime()` 用 `getMonth()/getDate()/
getHours()/getMinutes()` 手工拼接成 `M/D H:MM`。该实现与原版库卡片
副标题在两个维度上偏离：格式（数字拼接 vs locale-aware 中号日期）与
分量（带 24 小时时间 vs 纯日期）。

## 决策

1. **库卡片副标题**：改为
   `new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' })`，
   等价于原版 `z5c.n` → `x2f(0)` =
   `DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)`。
   `Instant.ofEpochMilli` 输入即 `Date(milliseconds)`；`undefined`
   locale 随系统语言，与原版默认 locale 行为一致。
2. **扫描文档默认标题**（`scanned_document_title` 的 `%1$s`）：
   改用 `{ dateStyle: 'medium', timeStyle: 'short' }` —
   `z5c.j`（`ofLocalizedDateTime(MEDIUM, SHORT)`）等价物。
   原版的 `%1$s` 实参在 GMS 扫描深链内生成、JADX 不可直接读；
   选择 MEDIUM+SHORT 是有据可查的最近邻（`z5c.j` 存在即为此类
   场景），同时保留同一天多次扫描的标题唯一性。此为显式记录的
   合理近似，非声称逐位等价。
3. 兜底：两处 `Intl.DateTimeFormat` 均包 try/catch，失败时回退
   `M/D/YYYY` 数字日期（与 `RecordingPanel.ets` 既有 Intl 用法的
   容错风格一致）。
4. 不动 `gb6.b0/c0` 的字段选择（RECENT → `lastOpened`，其余 →
   `updatedAt`）——该规则已在前阶段验证一致。

## 影响

- `note/src/main/ets/ui/library/LibraryPage.ets`：
  `formatTime` 拆为 `formatLibraryDate` / `formatLibraryDateTime`；
  两处卡片副标题改用前者，扫描标题改用后者。
- `docs/migration/replays/d02-original-library-doc-scan.mjs`：
  更新 `formatTime(Date.now())` → `formatLibraryDateTime(Date.now())`
  的调用点 pin。
- 可见差异：卡片副标题从 `1/5 14:30` 变为 `Jan 5, 2026`（en）/
  `2026年1月5日`（zh_CN），与原版一致。
