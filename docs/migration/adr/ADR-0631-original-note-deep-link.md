# ADR-0631：原版 `/app/note/<id>` 深链（py2 → hv7.i → 打开本地笔记）

- 状态：已接受
- 日期：2026-09-24
- 关联：Phase 664；前置 ADR-0628（共享入口）、ADR-0630（快捷方式）；
  证据 `evidence/phase-664-original-note-deep-link.md`；
  Replay `d05-original-note-deep-link.mjs`

## 背景

原版 `AndroidManifest.xml` 在 MainActivity 声明 `autoVerify` +
`BROWSABLE` 深链 filter：`http/https` + `notability.com` /
`*.notability.com`，`pathPrefix /app/note` 与 `/authlink`，
精确路径 `/event/learn-from-home[/]`、`/event/plus25[/]`。
`py2` 提供谓词/解析：`f`=host 谓词、`a`=恰 3 段 `app/note/<id>`、
`b`=`wtf.f`→`m18.r0`（恰 32 hex）→`ttf`、`c`=`/authlink`→
`VerifyLink(userId,linkUUID)`、`d=e|g`=两条营销事件路径。
`hv7.i` 对 `py2.d(data)` 置 `Q.j` 后 `kx` 协程消费。

## 决策

1. `module.json5` 增挂**独立** skill 对象（Harmony 要求重定向
   链接不混入首个 home skill）：`entity.system.browsable` +
   `ohos.want.action.viewData` + `uris` 声明 `https`/`http` +
   `host notability.com` + `pathStartWith app/note`。不开
   `domainVerify`（域名关联文件需托管在 notability.com，非本
   工程可控）。
2. 新增 `DeepLinkIngress.ets`（与 `SharedFileIngress`/
   `LaunchActionIngress` 同构）：`parseDeepLinkNoteId` 按
   `py2.f`/`py2.a`/`m18.r0` 同规则校验（http/https、
   `notability.com` 或 `.notability.com` 结尾、恰 3 段、
   恰 32 hex），`enqueueDeepLinkWant` 只收 `viewData` want，
   `drainDeepLinkNoteIds` 原子清空。
3. `NoteAbility.onCreate/onNewWant` 均入队；`LibraryPage.
   onPageShow` 在共享/快捷 drain 之后 `drainDeepLinkIngress`。
4. `NoteRepositoryImpl.resolveDeepLinkNoteId`：先 `note_meta.id`
   直查活跃笔记（`deleted_at IS NULL`）；未命中查
   `note_sync_metadata.legacy_id`（导入改号副本在导入管线保留
   原 ID），命中再回验 `note_meta` 活跃性。
5. 命中 → `vm.loadNotes` 刷新快照后 `pushUrl NotePage`；未命中
   → `deep_link_note_missing` toast，停在资料库。全程复用
   `pageActive`/`createBusy`/`lifecycleGeneration`/`viewModel`
   守卫。

## 差异登记（fail-closed）

- `*.notability.com` 子域：Harmony `uris.host` 无通配符 → 仅声明
  裸域；解析层仍保留子域语义。
- `domainVerify`：需在目标域托管 applinking 关联文件，不可行；
  不声明验证（AppLinking 直开不可用，显式 want 路由不受影响）。
- `/authlink`（VerifyLink）与 `/event/*`（`py2.d`→`Q.j`）：
  账号后端校验/营销事件，订阅域 —— 不声明不实现。
- 未命中笔记：原版 `kx` 内订阅后端同步取回（opaque 但唯一合理
  语义）→ Harmony 弹 toast fail-closed。
- 回收站目标：`deleted_at` 非空按未命中处理（无原版证据）。

## 验证

- 专项 fixture `d05-original-note-deep-link.mjs`：30 断言全绿
  （manifest/py2/m18/hv7 证据 + 声明/解析/管线/落地/字符串 +
  既有 ingress 回归保护）。
- 全量 Desktop Replay 549/549。
- `note@default` + `note@ohosTest` 双 HAP 构建 0 错误。
- 未启动模拟器/真机/Hypium。
