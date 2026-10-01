# ADR-1349 Home "Upcoming exams" 分区 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：1413
- 接续：ADR-1348（Coming Up 日历分区）、ADR-0652（Learn/AI 面 fail-closed）、ADR-0716（syllabus 服务端解析）、ADR-0709（日历 schema）、ADR-0691/0694（Home 分区移植史）
- 证据：`docs/migration/evidence/phase-1413-home-exams.md`

## 背景

原版 Home 列序（`vkm.a`）：CTA → `kan.a` Coming Up → `q8n.e`
Upcoming exams → unindexed → favorites → recents。Phase 1412 已移植
Coming Up；本 ADR 登记其后的 Exams 节。

Exams 数据链：`jt1.java:1589` 将课表条目 `lhh`（Room
`syllabusEvents` 表）合流为 `ag1{j=zf1.G(SYLLABUS), k=lhh.b 文件夹
引用, l=(g=="EXAM")}`；`xy5` case1 取 `l==true` 且开始时间落在
`[tomorrow0, today+8d0)` 的事件，经 `k`→`ymm.d`→`cpj` 颜色→
`ip5.l`→`hp5` 课程文件夹解析成 `pij` 卡（倒计时 tomorrow/days_until
复数 + 日期 + 标题 + 文件夹 chip + Review 按钮），`rij` 非空才渲染。

## 判定依据

1. `cbl.java:232`：设备日历事件构造恒 `zf1.F, k=null, l=false`——
   **设备路径结构上无法产出考试卡**；Phase 1412 的
   `calendarManager` 管道不受此判定影响。
2. `syllabusEvents` 唯一写入方是 `uih`→`ih4`→`rgh` 课表解析入库链，
   属 `data.learn.syllabus`（Learn 后端服务端解析，Phase 772/
   ADR-0716 已钉：`syllabus_error_server_busy`/`timed_out`/
   `too_large`/`not_syllabus`）。
3. 卡片自身亦双重后端绑定：文件夹 chip 依赖 `syllabusCourses`↔
   库文件夹颜色链；主按钮 `acm` case6 = `aisparkle_med_bold` +
   `home_exam_review`，即 Learn AI Review 入口（ADR-0652 已
   fail-closed）。

## 决定

- **不实现** Home Upcoming exams 分区，等价于原版无课表数据时
  `rijVar==null` → `q8n.e` 不渲染的可观察行为（节整体缺省）。
- `note/src` 无变更；Coming Up 模型保留的 `source`/`isExam` 语义位
  空置并登记（与 `ag1.k/l` 对应，供将来后端等价物出现时直接复用
  `xy5` 窗格规格）。
- 原版字符串 `home_upcoming_exams_title`/`home_exam_tomorrow`/
  `home_exam_days_until`/`home_exam_open_folder`/`home_exam_review`
  不入 Harmony string.json（无 UI 消费方）。

## 后果

- 利：无伪造数据/无半实现 UI；Home 顺序与原版"无课表"态一致；
  Replay 以 fail-closed 钉件防止后续误加半吊子考试卡。
- 弊：若用户曾在原版导入课表，迁移后其考试卡不再出现——与原
  版"课表数据未同步到新设备"的行为一致（数据本就随 Learn 后端
  而非本地迁移）。
