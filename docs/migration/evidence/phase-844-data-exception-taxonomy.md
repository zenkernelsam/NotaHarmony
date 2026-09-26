# Phase 844 — data 域异常分类学尾部闭合

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/`
全包 `*Exception`/`*Error` 盘点 = **64 个类型化异常**。
840（ops/synced×6）、841（core×9）、842（billing×11）、
843（Zendesk×1）之后剩余 **32 个未登记**，本相位补齐。

## 一、剩余 32 类（按包）

- `backgroundwork`：`PreemptedByOpenNoteException`（后台工作被
  打开笔记抢占的取消信号）；
- `gallery`：`GalleryPublishException`（作品发布失败）；
- `handwritingrecognition`（7 类）：`HandwritingEngineUnavailable`
  /`LanguagePackUnavailable`/`MathRecognitionUnsupported`/
  `PlayAssetDeliveryUnavailable`（Play 资源包下载）/
  `hwr.PenSampleDecoding`/`hwr.RemoteEngine`（:hwr 远程进程）/
  `myscript.MyScriptEngineFeed`；
- `learn`：`LearnError` + `syllabus.SyllabusParseException`；
- `library/state`（8 类）：`NoteAccessDenied`/`NoteNotFound`/
  `RetryableUpload`/`UploadInProgress`/`folders.InvalidFolderName`/
  `folders.MaxFolderDepthExceeded`/`notelimit.NoteLimitRefused`
  （消息 "Note limit reached"，839）/`ntb.MissingAssets`；
- `loginstate`（3 类）：`LibraryInitTimeout`/`LoginTeardown`/
  `PostCommitLogin`；
- `transcription`（4 类）：`Transcription`/`TranscriptionNotFound`/
  `livetranscription.LiveTranscriptionHttp`/`upload.GCSUpload`；
- `user`（4 类）：`MalformedPasskeyPayload`/`NullAuthToken`/
  `PasskeyActivityGone`/`SsoVerification`；
- `core/flatbuffers`：`ValidationException`；
- `ui/fileimport`：`PartialImportException`（部分导入）。

## 二、Harmony 类型化错误面（9 类）

`PencilSplatLimitError`、`BackupPreparationError` +
`BackupSnapshotChangedError`、`MaxFolderDepthExceededError`、
`InvalidFolderNameError`、`OriginalInkPathDeferredError`、
`OriginalPhotoTooLargeError`、`RecordingDeferredError`、
`ShapeGroupDeferredError`。

## 三、映射表

| 原版 | Harmony | 状态 |
|------|---------|------|
| InvalidFolderName | InvalidFolderNameError | **类型对齐** |
| MaxFolderDepthExceeded | MaxFolderDepthExceededError | **类型对齐** |
| SnapshotFormat/Unsupported | BackupPreparationError 族 | 近似映射 |
| PartialImport | generic Error（NoteImporter） | 泛化 |
| library state 上传四元 | generic Error | 泛化 |
| transcription×4、learn×2、gallery、
hwr×7、loginstate×3、user×4、
flatbuffers、notelimit、backgroundwork | 无对应面 | fail-closed |

## 四、结论

64 类异常分类学**全部归因**（840/841/842/843/844 五相位
合计覆盖）。类型对齐 2 类、近似/泛化若干，其余 fail-closed。
