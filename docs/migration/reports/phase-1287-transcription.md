# Phase 1287 报告 — 转写层

## 完成内容

- `TranscriptionDatabase`(Room)+`LiveTranscriptionHttp
  Exception{int status}`+`upload/GCSUploadException`+
  `TranscriptionException`/`NotFoundException` —— 语音
  笔记→文本管线：AudioRecord(Phase 1196)→上传 GCS→
  HTTP 实时转写→Room 缓存；转写引擎在服务端。

## 产出

- evidence `phase-1287-transcription.md`
- fixture `d02-transcription.mjs`（10/10）
- ADR-1231（后端依赖部分 fail-closed）
