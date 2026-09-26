# 原版 1.4.2 日历/教学大纲数据库 Schema 登记（Phase 765 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/calendar/database/`
>   + `sources/defpackage/{yf1,wf1,yg1,zg1,xg1,f54,rgh,ohh,wg1,w73,lr,fch,sx0,lo,s0}.java`
> 性质：1.4.2 版本差证据登记（ADR-0708"版本差·待审"细化）；无 Harmony 代码变更。

## 一、数据库与实体

`CalendarDatabase`（`calendar/database/CalendarDatabase(_Impl).java`，独立 Room
数据库文件）暴露三个 DAO（`u()`→`zg1`、`v()`→`f54`、`w()`→`rgh`）。
失效追踪器 `ky7` 声明恰好 **4 张表**：

- `calendarSelections`
- `calendarDismissedEvents`
- `syllabusCourses`
- `syllabusEvents`

（`CalendarDatabase` 字符串表中的 `"calendar"` 为 schema 目录名，非实体表。）

实体类（混淆名）：`ah1`=CalendarSelectionEntity、`sgh`=SyllabusCourse、
`lhh`=SyllabusEvent；DismissedEventEntity 的名称见 `yf1.java` 的 Room 校验
错误串 `DismissedEventEntity(com.gingerlabs.notability.data.calendar.database.DismissedEventEntity)`。

## 二、DDL 原文（`yf1`/`wf1` RoomOpenHelper 代理）

```sql
CREATE TABLE IF NOT EXISTS `calendarSelections` (`calendarId` TEXT NOT NULL, PRIMARY KEY(`calendarId`))
CREATE TABLE IF NOT EXISTS `calendarDismissedEvents` (`eventId` TEXT NOT NULL, `dismissedAtMillis` INTEGER NOT NULL, PRIMARY KEY(`eventId`))
CREATE TABLE IF NOT EXISTS `syllabusCourses` (`folderId` TEXT NOT NULL, `courseName` TEXT NOT NULL, `meetingTimeLine` TEXT, `importedAtMillis` INTEGER NOT NULL, PRIMARY KEY(`folderId`))
CREATE TABLE IF NOT EXISTS `syllabusEvents` (`id` TEXT NOT NULL, `folderId` TEXT NOT NULL, `title` TEXT NOT NULL, `startMillis` INTEGER NOT NULL, `endMillis` INTEGER NOT NULL, `isAllDay` INTEGER NOT NULL, `type` TEXT NOT NULL, PRIMARY KEY(`id`))
CREATE INDEX IF NOT EXISTS `index_syllabusEvents_folderId` ON `syllabusEvents` (`folderId`)
```

## 三、写路径（`yg1` 共享 INSERT 适配器，`switch (this.e)`）

| case | 实体 | 语句 |
|---|---|---|
| 0 | `ah1` | `INSERT OR REPLACE INTO calendarSelections (calendarId) VALUES (?)` |
| 5 | `sgh` | `INSERT OR ABORT INTO syllabusCourses (folderId,courseName,meetingTimeLine,importedAtMillis) VALUES (?,?,?,?)` |
| 6（default） | `lhh` | `INSERT OR ABORT INTO syllabusEvents (id,folderId,title,startMillis,endMillis,isAllDay,type) VALUES (?,?,?,?,?,?,?)` |

（`yg1` 其余 case 属其它数据库：CompletedQuizSession/LearnNoteState/PendingFollow/PendingLike。）

**缺口说明**：`calendarDismissedEvents` 的 INSERT 字面量在全部反编译输出中不存在
（INSERT 适配器全量枚举亦无此表）——疑似落入 JADX 未解出的 553 个类之一，或以
非字面量查询执行。登记为"静态不可恢复"，不臆造语句。

## 四、DAO/仓储语义

### `zg1`（日历选择 DAO，`CalendarDatabase.u()`）

- `a(Set<calendarId>)`：先 `DELETE FROM calendarSelections` 清空，再批量
  `INSERT OR REPLACE`——**整表替换**语义（`xg1` 协程 + `sx0(11)` + `s0(18)`）。
- 失效流：`SELECT calendarId FROM calendarSelections`（`sx0(12)`）。

### `f54`（日程隐藏 DAO，`CalendarDatabase.v()`）

- `w73(23)`：`SELECT eventId FROM calendarDismissedEvents`（失效流）。
- `lr(5)`：`DELETE FROM calendarDismissedEvents WHERE dismissedAtMillis < ?`
  ——`wg1.a()` 以 `now - 180d` 裁剪墓碑。

### `rgh`（教学大纲 DAO，`CalendarDatabase.w()`）

- 文件夹域替换：`DELETE FROM syllabusCourses WHERE folderId IN (...)` +
  `DELETE FROM syllabusEvents WHERE folderId IN (...)` 后批量插入（`lo` 事务）。
- 全清：`DELETE FROM syllabusCourses`、`DELETE FROM syllabusEvents`（`fch`）。
- 事件流：`SELECT * FROM syllabusEvents`（`fch(12)`，失效驱动）。
- 陈旧探测：`SELECT folderId FROM syllabusCourses WHERE importedAtMillis < ?`
  ——`ohh.b()` 以 `now - 1min` 判断导入新鲜度。
- 过期裁剪：`DELETE FROM syllabusEvents WHERE endMillis < ?`
  ——`ohh.a()` 以 `now - 180d` 保留窗口。

## 五、仓储层（`wg1` / `ohh`）

- `wg1`（CalendarRepository）：合并设备日历源 `y14`（CalendarContract 提供器，
  依赖 `READ_CALENDAR` 权限）+ `ohh.c` + 双 Room 失效流；`hh9` 为
  `ConcurrentHashMap` 去重集（`zg9.name + ":" + id`）；`btg(5000, MAX)` =
  5 秒防抖；`b()` 触发 `y14.g` 刷新。保留常量 `h = Duration.ofDays(180)`。
- `ohh`（SyllabusRepository）：事件流 + 180 天结束时间裁剪 + 1 分钟导入
  新鲜度 + 文件夹域事务替换。`d = 180d`、`e = 1min`。

## 六、语义总结

| 表 | 语义 |
|---|---|
| `calendarSelections` | 用户勾选要显示的设备日历集合（整表替换） |
| `calendarDismissedEvents` | "隐藏此事件"墓碑集，eventId 主键 + 时间戳，180 天滚动清理 |
| `syllabusCourses` | 每图书馆文件夹一门课程（folderId 主键），记录导入时刻 |
| `syllabusEvents` | 课程事件流（开始/结束/全天/类型），folderId 索引级联 |

两仓储共享 180 天保留窗口（墓碑 + 过期事件统一裁剪），5 秒防抖合并
Room 失效通知与设备日历变更。

## 七、Harmony 现状与分类

- Harmony 侧无任何日历/大纲表面（全仓 grep 命中为零）——纯 1.4.2 新特性。
- `syllabusCourses`/`syllabusEvents`：纯本地 Room 数据 + folderId 级联，
  **本地可移植**（依赖文件夹模型；导入来源为大纲解析器，属另一边界）。
- `calendarSelections`/`calendarDismissedEvents`：本地表，但数据源是
  **设备日历**（`y14`/CalendarContract）。HarmonyOS 侧对应
  `calendarManager`（API 11+）+ `ohos.permission.READ_CALENDAR`
  （system_basic ACL）——"本地可移植 + 平台权限边界"，非后端依赖。
- 登记为版本差·混合边界：本地 schema 可移植，设备日历读取需
  Harmony 日历权限适配验证（真机项）。
