# Phase 660：加密 PDF 导入的密码询问与解密重存

日期：2026-09-24
接续：Phase 659（Add GIF fail-closed）

## 原版依据

- `w7a` = `PasswordPromptState(fileName, isRetry)`——导入详情面板
  的密码询问状态，`isRetry` 标记错误重试。
- `zvh` 面板在 `w7aVar != null` 时渲染密码对话框
  `zvh.e(fileName, isRetry, onPasswordSubmitted, onPasswordCancelled)`，
  回调以 `o1(1, ou5, "onPasswordSubmitted(String)")` /
  `n3(0, ou5, "onPasswordCancelled()")` 绑定到 `ou5`
  ImportDetailsViewModel（持有 jv5/yq8/id7）。
- 语义：命中加密 → 弹密码框 → 提交重试（错误则 isRetry 再弹）→
  取消清除状态、中止该文件。
- 详见 `docs/migration/evidence/phase-660-original-encrypted-pdf-import.md`。

## Harmony 实现

- `NoteImporter.ets`
  - 新契约 `PdfPasswordPrompt = (fileName, attempt) => Promise<string|null>`，
    `attempt` 对应原版 `isRetry`（0 首问、>0 错误重试）。
  - `parseImportedPdf(path, decryptedPath, password)`：
    `PARSE_ERROR_PASSWORD(3)` → `passwordRequired`；密码成功 →
    `removeSecurity()` + `saveDocument()` 落无密码副本并读回；
    `finally` 必 `releaseDocument()`。
  - `stageAndParseImportedPdf`：while 重试循环——密码成功以**解密字节**
    继续（资产存储、sha512、fileSize、渲染全程无密码）；无回调 →
    `CORRUPTED` fail-closed；`null` → `CANCELLED`；finally 清理两个
    暂存文件。
  - 回调全链路透传（独立/入笔记/多选循环），仅 PDF 分支消费。
- `ui/components/PdfPasswordDialog.ets`：共享密码对话框
  （`InputType.Password` + 错误重试提示态）。
- `NotePage`/`LibraryPage`/`BackupPage`：各持
  `CustomDialogController` + Promise resolve；`aboutToDisappear`
  兜底 `resolve(null)` 防悬挂。
- 新字符串 `import_pdf_password_{title,hint,wrong,unlock}`（双语）。

## 决定（ADR-0627）

- 解密重存为导入语义：渲染层 `loadDocument(path)` 保持无密码契约，
  密码不持久化、不渗透渲染层。
- 原版取消仅清除面板状态；Harmony 无详情面板，取消即结束该文件导入
  （CANCELLED），多选时其余文件不受影响。

## 验证

- 桌面回放：新增 `d05-original-encrypted-pdf-import.mjs`（44 断言）；
  P652 资产断言、生命周期边界、多选循环签名三处旧 pin 同步更新。
- 全量 Desktop Replay 545/545 全绿（见提交信息）。
- HAP：`note@ohosTest` / `note@default` clean 构建通过（见提交信息）。
