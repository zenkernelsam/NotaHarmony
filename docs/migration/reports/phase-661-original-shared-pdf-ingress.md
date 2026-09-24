# Phase 661：外部共享/打开 PDF 入口（fag.h0 VIEW/SEND → 导入管线）

日期：2026-09-24
接续：Phase 660（加密 PDF 密码导入）

## 原版依据

- `AndroidManifest.xml`：`MissingNativeLibraryActivity` 注册
  `VIEW(content/file, application/pdf)` 与 `SEND(application/pdf)`
  intent-filter。
- `fag.h0(intent)`：SEND+pdf → `EXTRA_STREAM` URI；VIEW →
  content/file data URI；其余 → null。
- `hv7.i`：`fag.h0 != null` → `Q.j=true` 标记 + `kx(10)` 协程，
  共享 URI 进入与内建选择器相同的 `jv5` 嗅探分发管线。
- 详见 `docs/migration/evidence/phase-661-original-shared-pdf-ingress.md`。

## Harmony 实现

- `module.json5`：skills 追加 `viewData`/`sendData`/
  `sendMultipleData` + `uris:[{scheme:file,type:application/pdf}]`。
- 新增 `data/SharedFileIngress.ets`：`enqueueSharedWantUris`
  （viewData → `want.uri`；sendData/sendMultipleData →
  `parameters['ability.params.stream']` 数组逐项）+
  `drainSharedUris`（`splice` 原子清空）。
- `NoteAbility`：`onCreate`/`onNewWant` 均入队。
- `NoteImporter.importSharedUris`：公开入口 →
  `importPickedFilesStandalone`（同一读取+嗅探+逐文件物化 +
  密码回调透传）。
- `LibraryPage.onPageShow` → `drainSharedIngress` →
  `importSharedAndOpen`：沿用 `importAndOpen` 的
  `pageActive`/`createBusy`/`lifecycleGeneration` 守卫，成功后
  `router.pushUrl` 打开最后一篇导入笔记。

## 决定（ADR-0628）

- skill uri 收窄 application/pdf（同原版 manifest）；want 到达后
  不二次校验 MIME，内容嗅探分发——与 `fag.h0` 宽松行为一致。
- `sendMultipleData` 为平台等价扩展（原版仅 EXTRA_STREAM 单 URI）。
- 真机 fileshare 权限窗口未验证，登记为设备侧待验项。

## 验证

- 桌面回放：`d05-original-shared-pdf-ingress.mjs` 19 断言绿。
- 全量 Desktop Replay 546/546 全绿（见提交信息）。
- HAP：`note@ohosTest` / `note@default` clean 构建通过。
