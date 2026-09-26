# 原版 1.4.2 大纲解析管道与新增异常族登记（Phase 772 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/resources/res/values/strings.xml`、
>   `sources/com/gingerlabs/notability/data/learn/syllabus/`、
>   `data/library/state/notelimit/`、两版本 `*Exception`/`Error` 类名 diff
> 性质：1.4.2 版本差证据登记 + Phase 765 syllabus 分类细化；无 Harmony 代码变更。

## 一、大纲导入管道（服务端解析）

字符串键揭示完整 UX 链：

| 阶段 | 键 | 文案 |
|---|---|---|
| 入口 | `syllabus_choose_file` / `syllabus_choose_photos` | Choose a file / 拍照导入 |
| 解析中 | `syllabus_parsing_header/body` | "Extracting key dates and assignments" |
| 服务端错误 | `error_not_syllabus`、`error_rate_limited`、<br>`error_server_busy`（"Lots of syllabuses are being read right now"）、<br>`error_timed_out`、`error_too_large`、`error_unavailable` | 均为服务端响应态 |
| 复核 | `syllabus_review_banner` / `review_banner_no_dates` | "Review the course name and dates below." |
| 持久化 | （Phase 765 四表） | `syllabusCourses`(folderId PK) + `syllabusEvents` |
| 展示 | `course_section`/`exams_section`/`recurring_section`/<br>`no_upcoming_dates`/`fallback_course_name`="New course" | 课节/考试/周期分区 |

`SyllabusParseException` 位于 `data/learn/syllabus/`——属 Learn 簇。
**细化 Phase 765 判定**：syllabus 表虽为本地 schema，其唯一数据源是
服务端解析（上传文件/照片 → 服务端抽取日期 → 复核 → 落库），
故该功能整体为**后端耦合**，非"本地可移植"——表可移植但无生产者。
ADR-0709 相应表述以本阶段为准。

## 二、1.4.2 新增异常/错误类全量（19 个）

| 类 | 归属簇 | 处置 |
|---|---|---|
| MalformedPasskeyPayload / PasskeyActivityGone / SsoVerification / NullAuthToken | Passkey/SSO | Phase 771 fail-closed |
| RemoteEngine / PenSampleDecoding / MyScriptEngineFeed / HandwritingEngineUnavailable | HWR | Phase 768 fail-closed |
| GalleryPublishException | 画廊发布 | Phase 766 fail-closed |
| SyllabusParseException | Learn/大纲导入 | 本阶段——后端边界 |
| NoteLimitRefusedException | `data/library/state/notelimit/` 订阅笔记上限 | fail-closed（付费墙，ADR-0708） |
| LoginTeardown / PostCommitLoginException | 登录生命周期 | 账号边界 fail-closed |
| LibraryInitTimeoutException | 图书馆初始化超时 | 本地语义可借鉴（初始化超时上报） |
| NoteOpsGone / PreemptedByOpenNoteException | 笔记操作生命周期 | 本地语义可借鉴 |
| SnapshotFormat / SnapshotUnsupportedException | 同步 op 序校验 | 同步后端 fail-closed |
| FirebaseLogger$LoggedError | 遥测 | GMS 边界 |

## 三、语义亮点

- `NoteLimitRefusedException` 证明笔记创建上限校验在
  **客户端**抛出（notelimit 包于 library/state 下）——付费墙决策
  有本地组件，但上限值/订阅态仍属后端。
- `PreemptedByOpenNoteException`/`NoteOpsGoneException`：打开中的
  笔记抢占挂起操作——并发语义值得 Harmony 侧记录。
