# 原版 1.4.2 反编译登记与版本差异初筛（Phase 760 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 输入：`C:\Users\Cisco He\Desktop\Notability\Notability_1.4.2\`（用户预下载）
> 产出：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.4.2\`（jadx-1.5.6，与 1.0.3 同法）
> 性质：证据登记 + 差异初筛；不构成任何 Harmony 代码变更，不替代 T-042 最终交付。

## 一、产物指纹

| 文件 | 大小 | SHA-256 |
|------|------|---------|
| `Notability_1.4.2/Notability%3A+AI+Note+Workspace_1.4.2_apkcombo.com.xapk` | 393,138,231 B | `d754ab3b2796ec4232996819f102d7adbbfe2ec9cdbd286cdd43d2993a20ff70` |
| `Notability_1.4.2/com.gingerlabs.notability.apk`（xapk 内 base APK） | 90,782,868 B | `764af402881befd7fa1c52d3688b2a1e91f4decaa41ddd42af0c313fbfe9f992` |

版本号对照（`resources/AndroidManifest.xml`）：

| 版本 | versionCode | versionName |
|------|-------------|-------------|
| 1.0.1 | 1001 | 1.0.1 |
| 1.0.3 | 1014 | 1.0.3 |
| 1.4.2 | 1040002 | 1.4.2 |

反编译规模：jadx 处理 18,071 类，产出 `sources/` 下 24,808 个 `.java` 文件
（1.0.3 为 21,108 个）；553 个类反编译失败（混淆应用常态，与 1.0.3 同类情况）。

## 二、差异方法说明

`defpackage/` 混淆类名在两版本间整体重排，按类名 diff 无意义。
有效差异面取自**非混淆签名面**：`com/gingerlabs/` 真实包结构、
`AndroidManifest.xml` 组件/权限、`res/values/strings.xml` 键名、第三方库目录。

## 三、`com.gingerlabs` 新增包簇（1.4.2 相对 1.0.3：+42 / −2）

| 新包/类簇 | 推断功能 | 初步处置 |
|-----------|----------|----------|
| `data/calendar/database/CalendarDatabase(+_Impl)` | 日历事件本地库（配合 `READ_CALENDAR`） | 后端/OS 集成边界，见 ADR-0708 |
| `data/gallery/`（`GalleryPublishException`、`outbox/GalleryMutationDatabase(+_Impl)`、`GalleryMutationUploaderWorker`） | Gallery 笔记发布 outbox 上传管线 | 私有后端边界 |
| `data/templates/database/CustomTemplatesDatabase(+_Impl)`、`data/templates/sync/CustomTemplateSyncWorker`、`data/settings/sync/TemplatePageSyncWorker` | 自定义模板库 + 云端同步 | 本地 CRUD 待审、同步为后端边界 |
| `data/handwritingrecognition/hwr/`（`HwrEngineService` 为 manifest 声明 Service、`RemoteEngineException`、`PenSampleDecodingException`）、`myscript/MyScriptEngineFeedException` | 新增远端手写识别引擎服务 | 私有后端/MyScript 边界 |
| `data/user/`（`MalformedPasskeyPayloadException`、`PasskeyActivityGoneException`、`SsoVerificationException`、`NullAuthTokenException`） | Passkey/SSO 登录 | 账号后端边界 |
| `feature/note/stickers/packs/`（`StickerPackDownloadWorker`、`StickerPackPrefetchWorker`） | 贴纸包下载/预取 | 后端资产分发边界 |
| `app/demo/DemoResetWorker` | Demo 模式重置 | 平台/演示边界 |
| `data/learn/syllabus/SyllabusParseException` | 课程表解析（Learn 域） | 服务端解析边界 |
| `data/library/state/notelimit/NoteLimitRefusedException` | 免费额度笔记数上限 | 订阅后端边界 |
| `domain/maintenance/`（`BackgroundMaintenanceWorker`、`ForegroundReturned`） | 后台维护任务 | 平台 WorkManager 边界 |
| `core/model/snapshot/`（`SnapshotFormatException`、`SnapshotUnsupportedException`） | 同步快照/操作序基础设施（Unsupported 消息为 "pending seq playable without an op id"，指向 synced-ops 定序；两异常类在 sources 内无直接引用点，疑为休眠/远端协议配套） | 协作后端边界 |
| `data/backgroundwork/PreemptedByOpenNoteException`、`core/workmanager/UnresolvableWorker`、`data/loginstate/`×3、`app/ApiGatedFirebaseInitProvider`、`core/common/logging/FirebaseLogger$LoggedError` | 后台任务/登录态/Firebase 杂项 | 平台/后端边界 |

被移除：`data/search/C$$__AppSearch__SearchResult`、`data/search/SearchResult`
（迁移至 `data/search/engine/appsearch/` —— AppSearch 引擎重构，非功能删除）。

## 四、AndroidManifest 差异

新增 `com.gingerlabs` 组件：

- `com.gingerlabs.notability.app.ApiGatedFirebaseInitProvider`
- `com.gingerlabs.notability.data.handwritingrecognition.hwr.HwrEngineService`

新增权限/特性：

- `android.permission.READ_CALENDAR`
- `com.google.firebase.components:com.google.firebase.crashlytics.ndk.CrashlyticsNdkRegistrar`

## 五、字符串键差异（strings.xml：1.0.3=1503 键 → 1.4.2=2118 键；+722 / −107）

新增键的功能族分布：`feature_*` 445、`ui_*` 257、其余 `call/mids/data/dream/status` 共 20。

主要新功能族（按键族统计）：

| 键族 | 规模 | 功能 | 处置方向 |
|------|------|------|----------|
| `feature_library_gallery__*` + `ui_gallery__*` + `ui_share__gallery_*` | ~200 | Gallery 社交化笔记分享（discover/following/trending、评论/点赞/收藏夹/发布/举报/remix、社交资料链接 Etsy/Instagram/TikTok/Twitter/YouTube） | 私有社区后端，fail-closed |
| `feature_note_stickers__*` | ~80 | 贴纸商店（40+ 命名贴纸包、下载/收藏/最近/自制贴纸） | 后端资产分发，fail-closed；`save_as_sticker` 本地候选待审 |
| `ui_templates__*` + `ui_papertemplates__*` | ~45 | 模板中心改版（分类浏览、自定义模板 CRUD、收藏/最近、interactive/repeat template、导入导出、Gallery 模板） | 本地部分待审；Gallery/同步为后端边界 |
| `ui_learn__syllabus_*` | ~30 | Learn 课程表导入（文件/照片选择、服务端解析、错误矩阵） | 服务端解析边界 |
| `feature_login__passkey_*` + `feature_settings__passkey_*` | ~10 | Passkey 登录/管理 | 凭据后端边界 |
| `feature_settings__calendars*`、`ui_permissions__calendar_*` | ~6 | 连接系统日历 | OS API 适配候选（Harmony 日历 Kit 另行评估） |
| `feature_paywall__note_limit_offer_*` | ~12 | 笔记数上限付费墙 | 订阅后端边界 |
| `feature_library__flashcard_import_delimiter_*` | ~5 | 闪卡导入自定义分隔符 | 本地导入候选待审 |
| `ui_notecovers__preset_stickers` | 1 | 封面预设贴纸 | 待审 |

移除 107 键：`abc_*`(20)/`exo`(16)/`mtrl`(15)/`material`(3) 等为 SDK 换版噪声；
`feature_*`/`ui_*` 移除 38 键，复核定性如下：

| 移除族 | 键数 | 定性 |
|--------|------|------|
| `feature_learn__chat_*`、`feature_learn_quiz__*`、`feature_learn_summary__*`、`feature_learn_transcription__*`、`feature_library__learn_card_score`、`feature_note__learn_toggle_description`、`feature_note__youtube_transcription` | ~15 | **Learn AI 聊天/测验/摘要/YouTube 转写在 1.4.2 被整体移除**（Learn 域重构为 syllabus 导入，非更名） |
| `feature_note__hwr_*`（panel_close/toggle_description） | 2 | HWR 面板 a11y 键移除——配合 `hwr/` 远端引擎重构，本地面板文案重组（待逐条复核更名去向） |
| `feature_settings__logout_*`、`_sign_out`、`_stay_signed_in` | ~8 | 登出流程键移除——账号体系迁移 Passkey/SSO 所致重构（待复核） |
| `feature_settings__dark_theme`、`match_system_appearance` | 2 | 主题设置键移除——设置项重构（待复核是否更名保留） |
| `feature_note__toprighttoolbar_undo/redo_action`、`content_manager_toggle_description` | 3 | 工具栏 a11y 键移除（更名或合并，待复核） |
| `feature_library__clear_search`、`ui_fileimport__back`、`ui_templates__browse`、其余零散 | ~8 | 单键更名/合并噪声 |

**重要含义**：Learn AI 族在 1.4.2 被移除说明原版自身有功能下线先例——
NotaHarmony 以 1.0.3 为基线保留对应 fail-closed 登记即可，无需回滚；
主题/登出/工具栏更名项列入 T-042 逐条复核输入。

**族级生存性校验**（按 `feature_*`/`ui_*` 键族归属统计）：
1.0.3 全部功能键族在 1.4.2 均有存活键，**无一族被整体移除**；
唯一收缩过半的是 `feature_learn`（17→8，AI 聊天下线、syllabus 等保留）。
结论：1.0.3 基线的功能面与 1.4.2 保持代表性一致，版本差集中在新增簇。

## 六、资源资产差异（resources/assets：115 → 576 文件，+465 / −4）

| 目录 | 1.0.3 | 1.4.2 | 内容 | 处置方向 |
|------|-------|-------|------|----------|
| `papertemplates/` | 0 | 446 | **36 个内置纸张模板包**（assignment_planner、college_rule、cornell、daily_* 系列、engineering_grid、hexagonal_grid、isometic、manuscript、mizige 米字格、tianzege 田字格、music_staves、各 planner 等）；每包含多尺寸/颜色/方向 PDF + `metadata.json` + HEIC 缩略图 | 模板中心改版本体；本地 PDF 资产可移植候选（待审：PDF 纸张模板渲染链） |
| `brushpacks/` | 0 | 5 | 新笔刷包 droidrocket/glitter/io/music/rainbow（`.brushpack` 格式） | 新笔型资产；格式与渲染契约待审 |
| `covers/` | 0 | 10 | 笔记封面 PDF（blue/brown/maroon/orange/purple/sage/yellow、*-journal、logo-pattern、stickers） | 封面资产；选择器 UI 为新增面 |
| `conf-lite/` + `resources/en_US/*.lite.res` | 4 | 0 | **MyScript lite 端侧识别资源整体移除**（en_US ak-cur/ak-superimposed/lk-text lite res + conf-lite） | 1.4.2 端侧 lite 识别下线，配合 `HwrEngineService` 远端引擎——MyScript 边界内版本差异 |
| `resources/`（iink 全量 res 含 math-sr/dl-raw-content） | 10 | 7 | 全量 iink 资源仍在但 `math-sr.res`（14.8→13.5MB）、`dl-raw-content.res`（4.8→4.6MB）换版 | iink SDK 升级配套 |

## 七、第三方库差异

- 新增 `com/github/luben/zstd`（zstd-jni 压缩库）——全树未见 `Zstd.compress/decompress`
  应用层调用点，判定为网络层传递依赖（OkHttp/Retrofit 系 zstd 响应压缩），
  **不构成 .note 本地格式变更信号**。
- `com/myscript/iink` 新增 `ImageFit` 等 —— iink SDK 升级。
- `com/google/firebase/crashlytics/ndk`、Material `FocusRingDrawable` 等 —— SDK 升级。
- 移除 `androidx/browser`、`androidx/coordinatorlayout`、`com/fasterxml`（Jackson）等。

## 八、结论

1.4.2 是一次**服务化大版本**：新增功能几乎全部围绕私有后端（Gallery 社区、
贴纸商店、模板云同步、远端 HWR、Passkey/SSO、课程表解析、笔记上限）。
对以 1.0.3 为基线的 NotaHarmony，这些均落入既有"后端/私有服务 fail-closed"
处置框架；本地候选（模板 CRUD、闪卡分隔符、日历连接、save_as_sticker）登记为
待审版本差项。详细逐簇复核是 T-042 的直接输入，本阶段不做逐类移植判定。
