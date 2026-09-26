# Phase 765 — 原版 1.4.2 日历/大纲 Room Schema 登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-765-original-calendar-schema.md`
ADR：`ADR-0709-original-calendar-schema.md`
Replay：`d02-original-calendar-schema.mjs`（15/15）

## 本阶段做了什么

继 Phase 764（CustomTemplatesDatabase）之后，对 1.4.2 第二个新增本地数据库
`CalendarDatabase` 执行同等 Room 生成代码取证：从 `yf1`/`wf1` RoomOpenHelper
代理、`yg1` 共享 INSERT 适配器、`sx0`/`lr`/`w73`/`fch`/`lo`/`rgh` 查询适配器
与 `wg1`/`ohh` 仓储，完整恢复了四表 DDL 与全部可见 DAO 语句。

## 恢复的 schema

| 表 | 列（类型） | 主键/索引 | 语义 |
|---|---|---|---|
| calendarSelections | calendarId TEXT | PK calendarId | 用户勾选的设备日历集（整表替换） |
| calendarDismissedEvents | eventId TEXT, dismissedAtMillis INTEGER | PK eventId | "隐藏此事件"墓碑，180 天滚动裁剪 |
| syllabusCourses | folderId, courseName, meetingTimeLine(NULL), importedAtMillis | PK folderId | 每图书馆文件夹一门课 + 导入时刻 |
| syllabusEvents | id, folderId, title, startMillis, endMillis, isAllDay, type | PK id；idx folderId | 课程事件流，folderId 级联 |

## 关键语义

- 选择集：`DELETE 全清 + INSERT OR REPLACE` 整表替换（`zg1.a`）。
- 墓碑裁剪：`dismissedAtMillis < now-180d`（`wg1`，`Duration.ofDays(180)`）。
- 大纲：folderId 域内 `DELETE WHERE folderId IN (...) + 批量插入` 事务替换；
  `endMillis < now-180d` 过期裁剪；`importedAtMillis < now-1min` 陈旧探测；
  `SELECT * FROM syllabusEvents` 失效驱动事件流。两仓储 5 秒防抖。
- 数据源边界：`calendar*` 表由 `y14`（CalendarContract，READ_CALENDAR）供给；
  `syllabus*` 由大纲导入管道供给（1.4.2 新簇）。

## 静态缺口登记

`calendarDismissedEvents` 的 INSERT 字面量在全部反编译输出中不存在
（`kom` 适配器全量枚举无此表；疑落入 JADX 未解出类），登记为不可恢复，
不臆造语句。

## 分类与后续

ADR-0709 登记为**版本差·混合边界**：

- `syllabus*` 本地可移植（folderId 级联与 Harmony 文件夹模型同构），
  但导入源属另一 1.4.2 边界；
- `calendar*` 本地可移植 + 平台权限边界（Harmony `calendarManager` +
  `ohos.permission.READ_CALENDAR` system_basic ACL），若回移须过真机验证。

## 验收

- Replay fixture 15/15 绿；全量 Desktop Replay、双 HAP 构建随本阶段执行。
- 三项跟踪文档已更新；T-042 仍为 Goal 最后一项，本阶段仅为其积累证据。
