# Phase 664：原版 `/app/note/<id>` 深链（py2 → hv7.i → 打开本地笔记）

日期：2026-09-24
接续：Phase 663（桌面快捷方式）

## 原版依据

- `AndroidManifest.xml`：MainActivity `autoVerify`+`BROWSABLE`
  filter，`http/https` + `notability.com`/`*.notability.com`，
  `pathPrefix /app/note`、`/authlink`，精确 `/event/learn-from-home`
  与 `/event/plus25`。
- `py2`：`f`=scheme/host 谓词；`a`=恰 3 段 `["app","note",id]`；
  `b`=`wtf.f`→`m18.r0` 把**恰好 32 个十六进制位**（`ug5.c` 表
  `0-9a-fA-F`）解析成 `ttf` 笔记 ID；`c`=`/authlink`→
  `VerifyLink(userId,linkUUID)`；`d=e|g`=两条营销事件路径。
- `hv7.i`：`py2.d(data)` → `Q.j=true` + `kx` 协程消费；
  `kx.invokeSuspend` opaque（同 `re0`/`yq8.e`），打开本地笔记
  为唯一合理语义，未命中路径（订阅后端同步取回）登记
  fail-closed。
- 详见 `docs/migration/evidence/phase-664-original-note-deep-link.md`
  与 ADR-0631。

## Harmony 实现

- `module.json5` skills 增挂独立 skill 对象（重定向链接不混入
  home skill）：`entity.system.browsable` +
  `ohos.want.action.viewData` + `uris` 两条（`https`/`http` +
  `host notability.com` + `pathStartWith app/note`），不开
  `domainVerify`。
- `data/DeepLinkIngress.ets`（新）：`parseDeepLinkNoteId` 复刻
  `py2.f`（http/https + `notability.com` 或 `.notability.com`
  结尾）+ `py2.a`（恰 3 段）+ `m18.r0`/`ug5.c`（恰 32 hex）；
  `enqueueDeepLinkWant` 只收 `viewData` want 入进程内队列，
  `drainDeepLinkNoteIds` 原子清空 —— 与 SharedFileIngress /
  LaunchActionIngress 同构。
- `NoteAbility.onCreate/onNewWant` 均 `enqueueDeepLinkWant(want)`。
- `LibraryPage.onPageShow` → `drainDeepLinkIngress` →
  `openDeepLinkNotes`：`NoteRepositoryImpl.resolveDeepLinkNoteId`
  先 `note_meta.id` 直查（`deleted_at IS NULL`），未命中查
  `note_sync_metadata.legacy_id`（导入改号副本保留原 ID）并回验
  活跃性；命中 `vm.loadNotes` 刷新后 `pushUrl NotePage`，未命中
  弹 `deep_link_note_missing`（base=`Couldn't open link` /
  zh_CN=`无法打开链接`）。全程 `pageActive`/`createBusy`/
  `lifecycleGeneration`/`viewModel` 守卫。

## fail-closed 登记

- `*.notability.com` 子域：`uris.host` 无通配符 —— 只声明裸域；
  解析层保留子域语义。
- AppLinking `domainVerify`：域名关联文件需托管在 notability.com，
  不可行 —— 不声明；显式 want（`aa start -U`、open-with）路由
  不受影响。
- `/authlink` VerifyLink（账号后端校验）与 `/event/*` 营销事件：
  订阅域 —— 不声明不实现。
- 本地未命中：原版经 `kx` 走订阅后端同步取回 —— 弹 toast 停在
  资料库。
- 回收站目标：`deleted_at` 非空按未命中（无原版证据）。

## 验证

- `d05-original-note-deep-link.mjs`：30 断言全绿。
- 连带 fixture 全绿：shared-pdf-ingress 19/19、launcher-shortcuts
  26/26、new-note-quick-actions 24/24、take-photo-ingress 27/27、
  library-note-lifecycle 11/11（endMarker 改为
  `drainDeepLinkIngress`，createFn 切片语义不变）。
- 全量 Desktop Replay 549/549。
- `note@default` + `note@ohosTest` 双 HAP 构建 0 错误。
- 未启动模拟器/真机/Hypium。
