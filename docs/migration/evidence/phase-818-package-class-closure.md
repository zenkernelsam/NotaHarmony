# Phase 818 — 包级类数闭合(1.0.1→1.0.3 与 1.0.3→1.4.2)

## 目的

Phase 760/793 以"新增包"为粒度登记了类层差异;**既有包内的
类增删**未系统比对 —— 按包路径统计 `.java` 数可发现"包仍在但
类变了"的面。本阶段把类粒度对比补到包级，完成类层收敛。

## 取证路径

- `decompiled_{1.0.1,1.0.3,1.4.2}/sources/` 按目录统计 `.java` 数
  (defpackage/ 混淆名整体重排，按类名 diff 无意义 —— Phase 760)

## 1.0.1→1.0.3(类层印证 Phase 817 资源差)

| 包 | Δ | 性质 |
|---|---|---|
| `com/singular/sdk{,/internal,...}` | +74 | **Singular 归因 SDK 完整上车**(与 817 manifest/资源互证) |
| `sso/` | +2 | **Google Credential Manager 登录落地**:`a.java`(GetGoogleIdOption/GetSignInWithGoogleOption/GoogleIdTokenCredential)+ `GoogleCredentialException`(InvalidIdToken/UnexpectedCredential 密封类)—— 1.4.2 passkey/SSO 面(771)的前身 |
| `com/gingerlabs/notability/data/library/state` | +2 | `ExportFileProvider`、`ExportSweepWorker`(导出管线,与 manifest provider 互换互证) |
| `com/google/android/gms/internal/appset` | +2 | Play AppSet |
| `androidx/core/content`、`play_billing`/`blockstore` 混淆包 | 各 ±1 | 厂商类重排 |
| `defpackage` | +144 | 混淆体量增量 |

## 1.0.3→1.4.2(com.gingerlabs 域)

- 24 个包类数增加、1 个包减少。
- **19 个 "0→N" 即 Phase 793 登记的新包**(data/user、
  domain/maintenance、data/loginstate、hwr、gallery/outbox、
  myscript、appsearch、snapshot、calendar/database、
  stickers/packs、templates/database、demo、syllabus、
  backgroundwork、workmanager、templates/sync、settings/sync、
  notelimit、gallery)。
- **既有包新增类仅 5 个**:

| 类 | 包 | 归属 |
|---|---|---|
| `NoteOpsGoneException` | `data/note/ops/synced` | synced-ops 410-Gone 生命周期异常(协作后端面) |
| `HandwritingEngineUnavailableException` | `data/handwritingrecognition` | HWR 引擎不可用异常(Phase 768 面) |
| `ApiGatedFirebaseInitProvider` | `notability/app` | API 门控 Firebase 初始化(Phase 771) |
| `FirebaseLogger$LoggedError` | `core/common/logging` | Firebase 错误上报类型 |
| `l.java` | `ui/support/data` | 混淆的 support 数据辅助类 |

- **减少 1 个**:`data/search` 2→0 —— 非删除,`SearchResult` 与
  `C$$__AppSearch__SearchResult` 移入 `data/search/engine/appsearch`
  子包(Phase 785 登记的 AppSearch 引擎层)—— 包内重定位。

## 结论

类粒度对比闭合：1.0.1→1.0.3 的代码层增量(Singular/sso/state)
与资源/manifest 层结论逐项互证;1.0.3→1.4.2 的既有包新增类
仅 5 个且全部归属已登记集群；`data/search` 的 0 化是包内
重定位而非下线。com.gingerlabs 域的类层差异面登记完毕。
