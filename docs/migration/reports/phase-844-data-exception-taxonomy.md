# Phase 844 — data 域异常分类学尾部闭合

## 范围

原版 `com.gingerlabs.notability` 全包 `*Exception`/`*Error`
盘点：64 类，本相位收尾剩余 32 类。

## 原版发现（32 类按包）

- `backgroundwork`：`PreemptedByOpenNote`（后台工作抢占取消）；
- `gallery`：`GalleryPublish`；
- `handwritingrecognition`×7：engine/language-pack/math/
  PlayAssetDelivery/pen-sample/remote-engine/MyScript feed；
- `learn`×2：`LearnError`/`SyllabusParse`；
- `library/state`×8：access-denied/not-found/retryable/
  in-progress/folder 校验×2/note-limit/ntb-missing-assets；
- `loginstate`×3、`transcription`×4（含 live-HTTP/GCS 上传）、
  `user`×4（passkey/sso/auth-token 族）、
  `core/flatbuffers`：`Validation`、`fileimport`：`PartialImport`。

## Harmony 映射

| 原版 | Harmony | 状态 |
|------|---------|------|
| InvalidFolderName | InvalidFolderNameError | 类型对齐 |
| MaxFolderDepthExceeded | MaxFolderDepthExceededError | 类型对齐 |
| SnapshotFormat/Unsupported | BackupPreparationError 族 | 近似 |
| 其余 29 类 | generic Error / 无对应面 | 泛化或 fail-closed |

Harmony 自有类型化错误 9 类（PencilSplat/Backup/Deferred/
PhotoTooLarge 等），其中文件夹校验两域达成类型对齐。

## 验证

- Replay `d02-data-exception-taxonomy.mjs`：**6/6**
  （64 类总数、32 尾部逐类核验、note-limit 消息、
  Harmony 3 项映射断言）。
- ADR-0788。**原版异常契约面完整闭合。**
