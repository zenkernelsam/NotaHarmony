# Phase 1287 证据 — transcription 转写层（GCS+HTTP）

来源：`data/transcription/*` + Phase 1196
`AudioCaptureService`。

## 组件

```
TranscriptionDatabase(.java + _Impl)   // Room 转写缓存
LiveTranscriptionHttpException{int I}  // HTTP 实时转写
                                       //（status code）
upload/GCSUploadException              // 上传到 GCS 失败
TranscriptionException / TranscriptionNotFoundException
```

## 管线（结合 Phase 1196 `AudioCaptureService`）

```
AudioRecord PCM（+PlaybackCapture 系统音频）
  → 编码/缓冲
  → upload → Google Cloud Storage（GCSUploadException）
  → HTTP 实时转写请求（LiveTranscriptionHttpException{status}）
  → 文本回传 → TranscriptionDatabase（Room 缓存+关联笔记）
```

→ **语音笔记→文本**特性：录音上传 GCS，服务端转写
（Speech-to-Text/自定义模型），实时回传缓存。

## 语义

- 转写引擎在**服务端**（GCS+后端转写服务）；
- 客户端 = 录音→上传→HTTP 轮询/流式接收转写文本 →
  Room 持久化；
- 错误分层：上传（GCS）/实时转写 HTTP/未找到/通用。

## Harmony 决策

转写 → Harmony 用 `rcp`/`http` 上传+轮询，或华为
`speech`/`audio` kit —— 录音/上传/缓存保真；GCS →
自有对象存储；转写服务需后端 —— 部分 fail-closed
（依赖后端转写服务）。

## 产出

- fixture `d02-transcription.mjs`（10 断言）。
- ADR-1231；中文报告。
