# Phase 1163 证据 — data/transcription + stylus + search

来源：`data/` 命名类。

## `data/transcription` = 转录（音频→文本）

```java
sealed TranscriptionException {   // @Metadata 10 子型
  Blocked, QuotaExceeded, HashingFailed,
  ServerPermanentError, ServerTransientError,
  PollingExhausted, UploadRetriesExhausted,
  CreateRetriesExhausted, TooManyErrors, NoNetwork }
livetranscription/LiveTranscriptionHttpException(int,String)
TranscriptionNotFoundException
upload/GCSUploadException          // Google Cloud Storage!
TranscriptionDatabase + _Impl     // Room
```

转录 = 后端服务（GCS 上传 + 轮询 + 实时转录）—— 10 类
失败语义 + Room 持久。**后端 fail-closed**。

## `data/stylus/haptic` = 手写笔触觉偏好

`HapticPreferencesInitializer implements g06` = DataStore
`Initializer`（`create(Context)`）—— 触控笔触觉反馈
设置持久。

## `data/search` = AppSearch + Room 索引

- `C$$__AppSearch__SearchResult implements ji3` =
  `androidx.appsearch` **生成类**（`$$__AppSearch__` 前缀
  codegen，`ji3` = Document iface）。
- `SearchResult(int, String×4)` = 结果记录。
- `SearchDatabase`/`SearchIndexDatabase` Room 索引。

## 语义

- 转录 = 后端（GCS+server）→ fail-closed。
- stylus 触觉 = DataStore 偏好 → Harmony preferences。
- 搜索 = AppSearch（全文索引）+ Room → Harmony
  relationalStore FTS。

## Harmony 决策

- 转录/上传 fail-closed；手写笔偏好 →
  `@ohos.data.preferences`；搜索 → relationalStore FTS5
  等价索引。
- 异常分类语义保。

## 产出

- fixture `d02-data-repos.mjs`（10 断言）。
- ADR-1107；中文报告。
