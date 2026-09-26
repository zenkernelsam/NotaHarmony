# Phase 847 — 1.0.3→1.4.2 类文件级增量闭合

证据：`decompiled_1.0.3` vs `decompiled_1.4.2`
`com.gingerlabs.notability` 包 `*.java` 文件级 diff。

## 一、总览

- 1.0.3：122 文件；1.4.2：162 文件；
- **+42 新增、−2 移除**——移除的两项即 `data/search/SearchResult`
  +生成适配器，**迁移**到 `data/search/engine/appsearch/`
  （818 包计数位移的文件级确认）；净增 **40 个新类**。

## 二、新增 42 按域

| 域 | 类 | 特征 |
|----|-----|------|
| calendar | CalendarDatabase(+Impl) | 1.4.2 日历簇（822 v2 库） |
| gallery | PublishException + outbox DB+Impl + UploaderWorker | 作品发布 outbox |
| handwritingrecognition | hwr×3(HwrEngineService/PenSampleDecoding/RemoteEngine) + MyScriptEngineFeed + myscript/a | :hwr 进程+MyScript |
| learn | syllabus.SyllabusParseException | 大纲解析 |
| library/state | notelimit.NoteLimitRefused | note 上限闸（839） |
| loginstate | LibraryInitTimeout/LoginTeardown/PostCommitLogin ×3 | 登录态机异常 |
| ops/synced | NoteOpsGoneException | 新增同步异常（840 层级叶） |
| search | appsearch/SearchResult+C$$__（自 data/search 迁入） | 包重组 |
| settings | sync.TemplatePageSyncWorker | 模板页同步 |
| templates | CustomTemplates DB+Impl + SyncWorker | 自定义模板簇 |
| user | Passkey/Sso/AuthToken ×4 | passkey+SSO 面（771） |
| domain/maintenance | BackgroundMaintenanceWorker + ForegroundReturned + a/b | 12h 维护链（828/845） |
| stickers | PackDownload+Prefetch Worker ×2 | 贴纸包（783/845） |
| app | ApiGatedFirebaseInitProvider + demo.DemoResetWorker | 829/845 |
| core | LoggedError + snapshot×2 + UnresolvableWorker | 日志/快照/占位桩 |
| backgroundwork | PreemptedByOpenNote | 抢占取消 |

## 三、与 818 的关系

818 记包级计数差（+22 包/+40 类净）；本相位给出**文件级**
完整名单，并确认 `data/search` 2 文件为迁移而非删除。

## 四、Harmony 映射

所有新增域均已在前序相位归口（sync/后端/hwr/passkey 等
fail-closed；calendar/sticker/template 登记）。无新增 Harmony
面要求——本相位为**版本增量完备性封存**。

## 五、结论

类文件级版本差分闭合：+42/−2（−2=迁移），40 净新类全部
映射到既有决定。
