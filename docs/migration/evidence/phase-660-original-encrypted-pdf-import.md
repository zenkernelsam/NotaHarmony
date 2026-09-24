# Phase 660 证据：加密 PDF 导入的密码询问与重试（ou5.onPasswordSubmitted）

日期：2026-09-24
关联：ADR-0627；前置 Phase 652（PDF 导入）、657（Add Files）、658（多选）

## 原版实现（decompiled_1.0.3）

### w7a = PasswordPromptState

`defpackage/w7a.java`（classes2.dex）：

```java
public final class w7a {
    public final String a;      // fileName
    public final boolean b;     // isRetry
    ...
    toString() → "PasswordPromptState(fileName=" + a + ", isRetry=" + b + ")"
}
```

导入详情面板持有的密码询问状态：**fileName** 指明哪个文件需要密码，
**isRetry** 标记上次密码错误后的重试（首次询问为 false）。

### zvh 导入详情面板（Compose）

`defpackage/zvh.java`（2209 行）在 `w7aVar != null` 时渲染密码对话框：

```java
String str6 = w7aVar.a;          // fileName
boolean z7 = w7aVar.b;           // isRetry
objS6 = new o1(1, ou5Var3, ou5.class,
    "onPasswordSubmitted", "onPasswordSubmitted(Ljava/lang/String;)V", 0, 27);
objS7 = new n3(0, ou5Var3, ou5.class,
    "onPasswordCancelled", "onPasswordCancelled()V", 0, 20);
...
e(str6, z7, ix4Var5, function6, uz4Var, 0);
```

`zvh.e(fileName, isRetry, onSubmitted, onCancelled)`（line 2168）内部走
`f2j.d(...)` AlertDialog：dismiss → `function0 = onPasswordCancelled`；
`le4(z, str, gl8Var, ix4Var, op4Var)` 为正文（isRetry 驱动错误提示态、
fileName 展示、gl8Var 密码输入态、ix4Var = onPasswordSubmitted）。

### ou5 = ImportDetailsViewModel

`defpackage/ou5.java`（315 行，`extends cs0`）持有 `jv5 L`（类型分发）、
`yq8 K`（reducer 应用）、`id7 M`（当前笔记 ops）——密码回调由面板
ViewModel 接收，提交后重跑分发；取消则清除 PromptState（w7a → null，
对话框消失）。

### 语义归纳

- 命中加密 PDF → 面板置 PasswordPromptState(fileName, isRetry=false)；
- 用户提交密码 → onPasswordSubmitted(str) 重试解析；失败 → 同状态
  isRetry=true 再弹（错误提示态）；
- 用户取消 → onPasswordCancelled() 清除状态，该文件导入中止。

## Harmony 能力与对齐（@hms.officeservice.pdfservice.d.ts）

| PDFKit API | 用途 |
|---|---|
| `loadDocument(path, password?)` | 带密码重试解析 |
| `ParseResult.PARSE_ERROR_PASSWORD = 3` | 密码必需/错误的显式信号 |
| `isEncrypted(path)` | （备用）加密预检 |
| `removeSecurity()` + `saveDocument(path)` | 解密后落无密码副本 |
| `setPdfPassword(pwd)` | 加密方向（本阶段未用） |

## Harmony 实现（note/src/main/ets/…）

- `data/NoteImporter.ets`
  - `PdfPasswordPrompt = (fileName, attempt) => Promise<string | null>`；
    attempt=0 首问、>0 重试（对应 isRetry）；null = 取消（对应
    onPasswordCancelled）。
  - `parseImportedPdf(path, decryptedPath, password)`：`loadDocument`
    命中 `PARSE_ERROR_PASSWORD` → `{passwordRequired: true}`；密码成功 →
    `removeSecurity()` + `saveDocument(decryptedPath)` + 读回
    `decryptedBytes`；`finally` 必 `releaseDocument()`。
  - `stageAndParseImportedPdf(...)`：`while(true)` 循环——密码成功 → 以
    解密字节为后续资产/尺寸来源；`passwordPrompt === undefined` →
    CORRUPTED fail-closed；`null` → CANCELLED；finally 清理两个暂存文件。
  - 回调沿 `importFromFile` / `importFileIntoNoteFromPicker` /
    `importFileIntoNote` / `importPickedFilesStandalone` /
    `importPickedFilesIntoNote` 全链路透传；仅 PDF 分支消费。
- `ui/components/PdfPasswordDialog.ets`（新增共享 @CustomDialog）：
  `InputType.Password` + `showPasswordIcon`；`attempt>0` 显示
  `import_pdf_password_wrong`；取消 → `finish(null)`。
- `ui/editor/NotePage.ets` / `ui/library/LibraryPage.ets` /
  `ui/settings/BackupPage.ets`：各持 `pdfPasswordResolve` + 一个
  `CustomDialogController`；`aboutToDisappear` 兜底 `resolve(null)`
  防悬挂 Promise。
- 字符串：`import_pdf_password_{title,hint,wrong,unlock}`（base + zh_CN）。

## 关键设计取舍

1. **解密重存**（decrypt-resave）：解密字节进入 `storeImportedOriginalAsset`
   并成为 assetHash/fileSize 的计量对象 → `PdfBackgroundLoader` 的
   `loadDocument(path)` 无需密码即可渲染，避免密码渗透进渲染层。
2. **回调而非全局状态**：`PdfPasswordPrompt` 沿调用链透传，不引入
   pending import 状态，与原版「面板状态驱动」语义等价且生命周期更短。
3. **无回调即 fail-closed**：内部/无 UI 调用点（如 .note 归档内嵌 PDF
   资产）拿不到密码 → CORRUPTED，不悬挂。
4. **多选逐文件**：rv5/qv5 循环中每个加密文件独立询问（原版逐文件
   PromptState 同语义）。

## 验证

- Replay `d05-original-encrypted-pdf-import.mjs`：44 断言全绿。
- 受影响旧 fixture（P652/生命周期/P658）同步更新后全绿。
- 全量 Desktop Replay 544 → 545 全绿。
- `note@ohosTest` / `note@default` 双 HAP clean 构建成功（仅存量告警）。
