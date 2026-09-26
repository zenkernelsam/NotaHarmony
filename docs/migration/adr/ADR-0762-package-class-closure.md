# ADR-0762 — 包级类数闭合(类粒度版本差收敛)

- 状态：Accepted
- 日期：2026-09-26
- 关联：ADR-0712(hwr)、Phase 760/767/771/785/793(包与类面)、
  Phase 817(1.0.x 行内差)

## 背景

类层差异此前只在"新增包"粒度登记;既有包内部的类增删与
1.0.1→1.0.3 的类层增量未系统比对。

## 取证结论

**1.0.1→1.0.3**:
- Singular SDK +74 类(`com/singular/sdk*`)—— 与 817 的
  manifest 权限/AppSet/kotlin_module 三方互证。
- `sso/` +2 —— Google Credential Manager 登录落地
  (`a.java` CredentialManager 调用 + `GoogleCredentialException`
  密封异常),为 1.4.2 passkey/SSO 面(771)的前身。
- `data/library/state` +2(`ExportFileProvider`/`ExportSweepWorker`)
  —— 与 manifest provider 互换互证。

**1.0.3→1.4.2(com.gingerlabs)**:
- 24 包增、1 包减；19 个增量包即 793 登记的新包。
- 既有包净新增仅 5 类:`NoteOpsGoneException`(synced-ops)、
  `HandwritingEngineUnavailableException`(hwr)、
  `ApiGatedFirebaseInitProvider`(771)、
  `FirebaseLogger$LoggedError`、`l.java`(混淆辅助)。
- `data/search` 2→0 为包内重定位(`SearchResult` 移入
  `engine/appsearch`,785 面),非功能下线。

## 决策

1. 类层差异按包级计数 + 既有包新增类清单登记;defpackage 混淆
   名重排维持 Phase 760 "按名 diff 无意义"的既有结论。
2. 5 个既有包新增类全部归属已登记集群，不产生新面。
3. `sso/` 在 1.0.3 的落地登记为 passkey/SSO 面的谱系前身。

## 后果

- 类粒度版本差在包级收敛：新增包(793)+ 既有包新增类
  (本 ADR)+ 包内重定位(data/search)三层证据齐备。
- Replay `d02-package-class-closure.mjs` 9/9 钉住。
