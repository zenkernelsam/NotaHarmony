# Phase 1413 证据：Library Home "Exams" 分区 —— fail-closed 判定

- 版本证据基线：`decompiled_1.4.2`（`sources/defpackage/` + `resources/res/values/strings.xml`）
- 结论：**fail-closed**。Exams 卡片仅由 SYLLABUS（Learn 后端课表解析）事件产生，无本地可移植数据源；卡片主操作 Review 本身亦属 Learn AI 面。

## 1. 事件源证据链（cbl / jt1 / zf1 / ag1 / lhh）

| 原版 | 行为 | 证据 |
|------|------|------|
| `cbl` 游标→`ag1` | 设备日历事件构造尾参恒为 `zf1.F`(DEVICE)、`k=null`、`l=false`——**设备事件永远不可能是考试** | `cbl.java:232` |
| `jt1` 合流 | SYLLABUS 事件：`new ag1(str4, null, str5, begin, end, "notability.syllabus", null, lhhVar.f, false, zf1.G, lhhVar.b, zx7.r(lhhVar.g,"EXAM"))`；仅当课表条目 `g=="EXAM"` 时 `l=true`，且 `k=lhhVar.b` 携带课程文件夹引用 | `jt1.java:1589` |
| `lhh` | `{a:id, b:folderRef, c:title, d:beginMs, e:endMs, f:allDay, g:type}`，来自 Room `syllabusEvents` 表 | `lhh.java`、`fch.java:89`(`SELECT * FROM syllabusEvents`) |
| `ih4`/`uih` | 把 `fl2`（课程条目）转 `lhh` 经 `rgh` 写入 `syllabusEvents`；`uih` = syllabus 文件解析管道（`oih{File,kih,ljh,ujh}`），包路径 `com.gingerlabs.notability.data.learn.syllabus` | `ih4.java:1405`、`uih.java:161/284` |
| Phase 772 既有钉 | syllabus 解析为**服务端**管道：`syllabus_error_server_busy`/`timed_out`/`too_large`/`not_syllabus`、`syllabus_review_banner`、`syllabus_exams_section` | `d02-original-syllabus-parse.mjs` |

## 2. 模型变换（xy5 case1 → pij → rij）

| 原版 | 语义 | 证据 |
|------|------|------|
| `xy5` case1 | ① 取 `bh1.a` 中 `ag1.l==true`（exam）且 `d ∈ [tomorrow0, today+8d0)`——**未来 7 天、不含今日**；② `e52.X3`+`iyi` 排序；③ 每条：`ag1.k`→`ymm.d`→`cpj` 颜色→`ip5.l(cpj)`→`hp5` 课程文件夹→`u07{title, id}`；任一环节 null → 丢弃该事件 | `xy5.java:283-326` |
| `pij` | `{a:eventId, b:title, c:daysUntil, d:LocalDate, e:cpj颜色, f:folderTitle, g:folderId}` | `pij.java` |
| `rij` | `UpcomingExamsState{cards:ArrayList<pij>}`；`arrayList6` 非空才 emit，否则 Home 不渲染该节 | `xy5.java:326-328`、`rij.java` |

## 3. 渲染（vkm / q8n.b / q8n.c / q8n.e / acm case6 / ig2）

| 原版 | 语义 | 证据 |
|------|------|------|
| `vkm.a` | Home 序：CTA → `kan.a`(Coming Up) → `q8n.e`(Exams，仅 `rijVar!=null`) → unindexed → favorites → recents | `vkm.java:404` |
| `q8n.e` | `bbn.b(home_upcoming_exams_title, …)` 节头 + 卡列表 | `q8n.java:463` |
| `q8n.b` | 卡体：`c==1`→`home_exam_tomorrow` 否则 `home_exam_days_until` 复数；`dateTimeFormatter.format(d)` 日期；`b` 空→`home_coming_up_untitled_event`；`q8n.c(f,g,function1)` 文件夹 chip | `q8n.java:128-213` |
| `q8n.c` | 文件夹 chip：整钮 a11y `home_exam_open_folder`，点击 → `function1`（打开课程文件夹） | `q8n.java:372` |
| `acm` case6 | 主按钮内容 = `aisparkle_med_bold` 图标 + `home_exam_review` 文本 → **"Review" 为 Learn AI 入口**，点击 → `function0` | `acm.java`、`ig2.java:142` |

## 4. fail-closed 判定理由

1. **数据源不可得**：`ag1.l=true` 只可能来自 `zf1.G` SYLLABUS 源；该源由 `syllabusEvents` Room 表供给，写入方是 Learn 服务端课表解析管道（`uih`→`ih4`→`rgh`），Phase 772/ADR-0716 已钉其为服务端特性；`d05-original-learn-ai-surface-fail-closed`/ADR-0652 已将 Learn 面整体 fail-closed。
2. **设备路径结构上不可能**：`cbl.java:232` 对 `CalendarContract` 事件硬编码 `l=false`、`k=null`——Phase 1412 的 Coming Up 管道在任何参数下都无法产出考试卡。
3. **卡片双重后端依赖**：文件夹 chip 需要 `syllabusCourses`↔库文件夹的颜色链解析（`ip5.l(cpj)`→`hp5`）；主按钮 Review 是 Learn AI 入口（`aisparkle_med_bold`），两者均无 Harmony 对应。
4. 因此 Home "Upcoming exams" 分区按旗标关闭态处理：**不渲染节、不声明行为**，与原版本地无课表数据时 `rijVar==null` → `q8n.e` 不渲染的可观察行为一致。

## 5. Harmony 落点

- 无 `note/src` 变更：Exams 节不实现；Home 顺序保持 CTA → Coming Up → Favorites → Recents → planners（`vkm` 中 Exams 位在无数据时本就缺省）。
- `HomeComingUpModel`/`OriginalComingUpCalendarGateway` 保留 `source`/`isExam` 语义位为空（Phase 1412 枚举位已留），文档化差异。
- 若未来 Learn/课表后端有等价 Harmony 服务，本 Phase 证据链（`xy5` 过滤窗、`pij` 字段、`q8n` 卡面）即为移植规格。
