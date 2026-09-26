# Phase 793 证据：原版 1.4.2 com.gingerlabs 包级全量归属

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——代码面包级收尾。
证据源：`decompiled_1.0.3/sources/com` vs `decompiled_1.4.2/
sources/com` 目录级 comm diff + 逐包类清单核对。
Replay：`docs/migration/replays/d02-original-package-closure.mjs`
ADR：`ADR-0737-original-package-closure.md`

## 1. 方法

`find sources/com -type d` 目录差集：1.4.2 新增 22 个
`com/gingerlabs/notability/**` 包（子目录计）。逐包核对
类清单并归属既有 Phase 簇。

## 2. 包→簇归属表

| 新包 | 内容 | 归属 |
|------|------|------|
| app/demo | 零售 demo 模式 | 775 worker |
| core/model/snapshot | SnapshotFormat/Unsupported 异常 | 772 |
| core/workmanager | WorkManager 基设 | 775 |
| data/backgroundwork | 后台任务基设 | 775 |
| data/calendar + /database | CalendarDatabase 5 表 | 765 |
| data/gallery + /outbox | 画廊社交 + PendingLike/Follow | 774/766 |
| data/handwritingrecognition/hwr | 本地 HWR 服务 | 768 |
| data/handwritingrecognition/myscript | MyScriptEngineFeedException | 768 |
| data/learn/syllabus | 课程表导入管线 | 772 |
| data/library/state/notelimit | 笔记数上限 | 788 |
| data/loginstate | PostCommitLogin 等 3 异常 | 771 登录域 |
| data/search/engine/appsearch | AppSearch 引擎 | 785 |
| data/settings/sync | TemplatePageSyncWorker | 769/775 |
| data/templates + /database + /sync | CustomTemplates DB + 上传 | 764/769 |
| data/user | passkey/SSO 4 异常 | 771 |
| domain/maintenance | BackgroundMaintenanceWorker | 775 |
| feature/note/stickers + /packs | 贴纸管理器 + 包下载 | 783/770 |

## 3. 核对要点

- `data/loginstate`：PostCommitLoginException（sealed，
  IOException）+ LibraryInitTimeout/LoginTeardown——
  登录生命周期错误域，归 771。
- `data/user`：MalformedPasskeyPayload/NullAuthToken/
  PasskeyActivityGone/SsoVerification——771 passkey/SSO。
- `domain/maintenance`：BackgroundMaintenanceWorker（
  CoroutineWorker，cs0 入参）已在 775 工人清单登记；
  ForegroundReturned 为其信号类。
- 全部包为零或薄实现（异常/接口/工人）；功能性包均已
  独立 Phase 深挖。

## 4. 结论

22 个新增 com.gingerlabs 包全量归属既有簇；代码面包级
差闭合。1.4.2 差面收敛于：字符串（+722 键，790）+ 资源
（791）+ 资产（761-764/792）+ 包（本阶段）+ manifest
（760/784）五维全部归属。
