# 原版库卡片日期格式 JADX 证据（2026-09-25）

Phase 738。本文件钉死原版 Notability 库列表卡片时间戳副标题的确切格式化
路径（`decompiled_1.0.3` 直接证据）。

## 结论

原版库卡片副标题使用 **`DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)`**
（locale-aware 中号日期，**不含时间分量**），作用于 epoch-milli；它
**不是** `M/D H:MM` 数字拼接。

## 证据链

1. `sources/defpackage/z5c.java:1911` — 卡片副标题格式化函数：
   ```java
   public static final String n(long j2) {
       String str = h.a().format(Instant.ofEpochMilli(j2));
       str.getClass();
       return str;
   }
   ```
2. `sources/defpackage/z5c.java:46-48` — `h` 为 `x2f(0)` 懒实例：
   ```java
   public static final zi h = new zi(new x2f(0));   // ofLocalizedDate(MEDIUM)
   public static final zi i = new zi(new x2f(1));   // ofLocalizedTime(SHORT)
   public static final zi j = new zi(new x2f(2));   // ofLocalizedDateTime(MEDIUM, SHORT)
   ```
3. `sources/defpackage/x2f.java:16-28` — `x2f.invoke()` switch：
   - `case 0` → `DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)`
   - `case 1` → `DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT)`
   - `case 2` → `DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM, FormatStyle.SHORT)`
4. `w09`（库卡片模型）构造点将 `z5c.n(...)` 产物写入 `w09.e`
   （卡片副标题字符串）：
   - `sources/defpackage/nk9.java:104` —
     `new w09(..., z5c.n(j89Var.m()), ...)`
   - `sources/defpackage/ok9.java:124` — 同上
   - `sources/defpackage/mk9.java:139` — 同上（folder 卡列表路径）
   - `j89Var.m()` / `k()` / `l()` = 缩略图路径、opId 与 epoch-milli 时间戳。
5. 字段选择规则已在先前阶段钉定：`gb6.b0/c0` — RECENT 分区取
   `lastOpened`，其余分区取 `updatedAt`；Harmony
   `LibraryPage.ets` 两处分区判断与该规则一致。
6. `z5c.i`（SHORT 时间）的实际消费者：`sources/defpackage/ar4.java` —
   `z5c.i.a().format(Instant.ofEpochMilli(hxfVar.b))`，为录音分段行
   时间戳，非库卡片路径。
7. `z5c.j`（MEDIUM 日期 + SHORT 时间）在 JADX 树中未见直接消费者；
   `scanned_document_title` 的 `%1$s` 实参在 `iid`/`rid` 协程深链内
   生成，未直接可读 — 参见 ADR-0686 的偏差记录。
8. 已排除的伪候选：
   - `ypd` — Gson `"MMM d, yyyy"` SQL-date 序列化适配器（非 UI）。
   - `zaj` — `"MMM d, yyyy h:mm:ss a"` 日志/时间戳边界（非 UI）。
   - `kf` — HTTP-Date 解析（网络边界）。
   - `wb0` — 耗时诊断格式化（非 UI）。
   - `m56.c` — `ofLocalizedDate(LONG)`，另一域（非库卡片）。

## Harmony 端口

`note/src/main/ets/ui/library/LibraryPage.ets`：

- `formatLibraryDate(timestamp)` →
  `new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' })` —
  locale-aware 中号日期，等价于 `ofLocalizedDate(MEDIUM)`；
  用于两处卡片副标题（`lastOpened` / `updatedAt` 选择不变）。
- `formatLibraryDateTime(timestamp)` →
  `{ dateStyle: 'medium', timeStyle: 'short' }` — `z5c.j` 等价物；
  用于 `scanned_document_title` 默认标题插值（保持连续扫描
  标题唯一）。
- 两者均带 try/catch 兜底（与 `RecordingPanel.ets` 既有
  `Intl.DateTimeFormat` 用法一致）。
