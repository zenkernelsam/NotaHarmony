# ADR-1107：data/transcription + stylus + search

## 状态

已接受（Phase 1163）。

## 决策

- 转录 = 后端（GCS 上传 + server + 实时）→ **fail-closed**；
  sealed `TranscriptionException` 10 子型语义保。
- stylus 触觉 = DataStore 偏好 → `@ohos.data.preferences`。
- 搜索 = `androidx.appsearch` + Room 索引 → Harmony
  relationalStore FTS5 等价。

## 依据

命名 `data/` 类（GCSUpload/LiveTranscription/密封 10 子型/
HapticPreferences/AppSearch codegen/SearchResult/Room）。

## 后果

Harmony：转录上传 fail-closed；触控笔偏好 preferences；
搜索 relationalStore FTS；异常分类语义保。
