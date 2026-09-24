# ADR-0628 外部共享/打开 PDF 入口（want → 导入管线）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：661
- 接续：ADR-0625（多选导入）、ADR-0627（加密 PDF 密码）
- 证据：`docs/migration/evidence/phase-661-original-shared-pdf-ingress.md`

## 背景

原版在 launcher 活动上注册 `VIEW(content/file, application/pdf)` 与
`SEND(application/pdf)` intent-filter；`fag.h0` 提取 EXTRA_STREAM /
content|file data URI，`hv7.i` 置启动标记后经 `kx` 协程进入与内建
选择器同一导入管线（独立笔记）。

Harmony 侧此前 `module.json5` 仅声明 `ohos.want.action.home`，外部
分享/「打开方式」无法进入应用——真实缺口。

## 决定

1. **声明 share skill**：`module.json5` 增加
   `ohos.want.action.viewData` / `sendData` / `sendMultipleData` +
   `uris:[{scheme:file,type:application/pdf}]`，与原版 mimeType 一致。
2. **`SharedFileIngress` 进程内队列**：`enqueueSharedWantUris(want)`
   解析 viewData（`want.uri`）与 sendData/sendMultipleData
   （`parameters['ability.params.stream']`，数组逐项）；`drainSharedUris`
   原子取出。want 早于 UI 到达，队列保证不丢。
3. **`NoteAbility` 接线**：`onCreate`/`onNewWant` 均入队。
4. **`LibraryPage.onPageShow` drain**：`importSharedAndOpen` 复用
   `importSharedUris` → `importPickedFilesStandalone`（与多选导入同一
   读取+嗅探+逐文件物化）+ `pdfPasswordPrompt`（Phase 660）；成功后
   `router.pushUrl` 打开最后一篇导入笔记。
5. **守卫**：沿用 `importAndOpen` 的 `pageActive`/`createBusy`/
   `lifecycleGeneration` 契约；CANCELLED 静默。

## 已登记偏差

- 原版 VIEW 的 `fag.h0` 不校验 MIME（manifest 之外任何 content/file
  URI 也进入管线）；Harmony skill 声明 pdf，但 want 到达后同样不二次
  校验，内容嗅探分发——宽松行为一致。
- `sendMultipleData` 原版无对应 action（EXTRA_STREAM 单 URI）；Harmony
  一并接收为多 URI 导入，属于平台等价扩展。
- 设备端共享流（fileshare/权限授予窗口）未经真机验证，静态实现与
  权限模型按 want.uri 直读约定。
