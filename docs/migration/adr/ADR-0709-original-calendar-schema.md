# ADR-0709 — 原版 1.4.2 日历/大纲 Room Schema 登记为混合边界版本差

日期：2026-09-29
状态：已登记（版本差·混合边界；不引入 Harmony 源码变更）
证据：`docs/migration/evidence/phase-765-original-calendar-schema.md`
Replay：`docs/migration/replays/d02-original-calendar-schema.mjs`
上游：ADR-0708（1.4.2 版本差处置范围）

## 背景

1.4.2 新增 `com.gingerlabs.notability.data.calendar.database.CalendarDatabase`
（独立 Room 数据库）+ 日历连接/课程大纲字符串簇。Phase 765 从 Room 生成代码
完整恢复了四表 DDL 与 DAO/仓储语义：

- `calendarSelections`（calendarId 主键；整表替换式选择集）
- `calendarDismissedEvents`（eventId 主键 + dismissedAtMillis 墓碑；180 天裁剪）
- `syllabusCourses`（folderId 主键——每图书馆文件夹一门课 + 导入时刻）
- `syllabusEvents`（id 主键 + folderId 索引级联；开始/结束/全天/类型）

两仓储（`wg1`/`ohh`）共享 180 天保留窗口与 5 秒失效防抖；大纲导入陈旧度
以 1 分钟 `importedAtMillis` 阈值判定。

## 决策

1. **登记为版本差·混合边界**，本阶段不移植任何表：
   - `syllabus*` 两表为纯本地数据 + folderId 级联，技术上可移植，但其
     数据源（大纲解析/导入管道）属另一 1.4.2 边界，先登记。
     （Phase 772/ADR-0716 细化：解析为服务端完成——文件/照片上传后经
     服务端抽取日期写回，故功能整体为后端耦合，表虽本地但无本地
     生产者。）
   - `calendar*` 两表为本地表，但事件源是 Android 设备日历
     （CalendarContract + `READ_CALENDAR`）；Harmony 对应
     `calendarManager`（API 11+）与 `ohos.permission.READ_CALENDAR`
     （system_basic ACL），属"可移植 + 平台权限边界"，需真机验证。
2. **墓碑语义保真登记**：dismiss 采用 eventId 墓碑 + `dismissedAtMillis`
   滚动 180 天清理；若后续移植，须保留"删事件不删源"语义与裁剪窗口。
3. **缺口登记**：`calendarDismissedEvents` 的 INSERT 字面量在反编译输出中
   不存在（全量 `kom` 适配器枚举亦无此表；疑似 JADX 未解出类之一）。
   按静态证据纪律登记为不可恢复，不臆造语句。

## 后果

- `d02-original-calendar-schema.mjs` 钉住四表 DDL、三类 INSERT、
  folderId 级联删除与 180 天裁剪常量；1.4.2 证据树更新即红。
- 日历/大纲功能是否回移由独立 Phase 判定；若回移，须先通过 Harmony
  calendarManager 权限可行性检查（建议列入 T-042 前的真机清单）。
- 字符串簇 `calendar_*`/`learn_syllabus_*` 与后端大纲解析 Worker 的
  处置仍以 ADR-0708 为准，本 ADR 仅新增本地 schema 证据。
