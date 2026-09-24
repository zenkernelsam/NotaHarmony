# ADR-0627 加密 PDF 导入的密码询问与解密重存

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：660
- 接续：ADR-0624（Add Files 入既有笔记）、ADR-0625（多选导入）
- 证据：`docs/migration/evidence/phase-660-original-encrypted-pdf-import.md`

## 背景

原版导入详情面板对加密 PDF 有完整密码流程：
`w7a = PasswordPromptState(fileName, isRetry)` 驱动密码对话框
（`zvh.e`），`onPasswordSubmitted(String)` 提交重试、
`onPasswordCancelled()` 取消清除——回调绑定在 `ou5`
ImportDetailsViewModel 上。

Harmony 侧此前把 `PARSE_ERROR_PASSWORD` 当普通解析失败处理，加密
PDF 一律 CORRUPTED，无询问入口。

## 决定

1. **实现密码询问流程**（对齐 ou5.onPasswordSubmitted/Cancelled）：
   - 新增 `PdfPasswordPrompt = (fileName, attempt) => Promise<string | null>`
     回调，沿 `importFromFile` / `importFileIntoNoteFromPicker` /
     `importFileIntoNote` / 两个多选循环透传，仅 PDF 分支消费。
   - `parseImportedPdf` 命中 `PARSE_ERROR_PASSWORD(3)` →
     `passwordRequired`；`stageAndParseImportedPdf` 循环调用回调：
     返回密码 → `loadDocument(path, password)` 重试；返回 null →
     `ImportResult.CANCELLED`；无回调 → `CORRUPTED` fail-closed。
   - `attempt` 对应原版 `isRetry`：0 首问、>0 错误重试（对话框显示
     「密码错误，请重试」）。
2. **解密重存为导入语义**：密码成功时 `removeSecurity()` +
   `saveDocument()` 落无密码暂存副本，**解密字节**作为
   `storeImportedOriginalAsset` 与 `assetHash/fileSize` 的来源——渲染层
   （`PdfBackgroundLoader.loadDocument(path)`）保持无密码契约，不引入
   密码持久化。
3. **UI 共享 `PdfPasswordDialog`**（`InputType.Password`），三个入口页
   （NotePage/LibraryPage/BackupPage）各持一个
   `CustomDialogController` + Promise resolve；页面销毁兜底
   `resolve(null)` 防悬挂。
4. **暂存文件生命周期**：`stagingPath`（原始字节）与 `decryptedPath`
   （解密字节）均在 finally 清理，与原暂存契约一致。

## 影响与已登记偏差

- 原版 `onPasswordCancelled` 只清除 PromptState 回详情面板；Harmony 无
  独立详情面板，取消直接结束该文件导入（报告 CANCELLED），选择器语义
  一致。
- `.note` 归档内嵌的加密 PDF 资产仍按既有路径处理（渲染侧既有
  fail-closed），不在本阶段范围。
- `isEncrypted`/`setPdfPassword` 备用 API 未消费。
