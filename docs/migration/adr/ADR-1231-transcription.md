# ADR-1231：转写层（GCS+HTTP）

## 状态

已接受（Phase 1287）—— **后端依赖部分 fail-closed**。

## 决策

转写 → Harmony `rcp`/`http` 上传+轮询或华为 `speech`
kit；GCS → 自有对象存储；转写服务依赖后端。

## 理由

`TranscriptionDatabase`(Room 缓存)+`GCSUploadException`
+`LiveTranscriptionHttpException{status}`+Transcription
Exception/NotFound —— 录音→GCS→HTTP 实时转写→缓存；
转写引擎在服务端。

## 后果

Harmony 转写 = http 上传+缓存；GCS/转写服务后端依赖
—— 客户端语义保真，后端服务 fail-closed。
