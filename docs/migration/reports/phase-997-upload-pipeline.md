# Phase 997 报告 — 上传管线

## 范围

oq1 上传客户端、wqf Retrofit 接口、aa6.r0 OpsBundle
生产、d8d RequestBody、ys2.k 响应解码、q89
NoteMutationResponse。纯审计。

## 原版发现

- 两端点：`collab-api/note/{id}/append?siteId=`、
  `collab-api/note/create?title&deviceId&noteId&createdAt`。
- createdAt = 末 op `uq9.k()` clientTime。
- createNote 前置校验：首 op 须 CreatePage 且
  pageCount>0，否则 IllegalArgumentException。
- 请求体 `d8d`：SharedMemory FlatBuffer → OkHttp
  RequestBody 零拷贝（`position(L)+write`），
  octet-stream，close 释放 shm。
- 响应 `q89`：`{noteId:utf 必需, acks:vq9[]}`
  —— OpAck 逐 op 回执（opId/acknowledged/errorMessage/
  冗余 op 回传）。
- 错误链：AssertionError→"Malformed NoteMutationResponse"
  →ozb；其他异常 `pzb.a` 检查→Error/Cancellation
  重抛，余包 ozb。

## Harmony 决策

后端依赖 fail-closed；协议已完整记录可复用。

## 产出

- 证据：`phase-997-upload-pipeline.md`
- Fixture：`d02-upload-pipeline.mjs`（21/21）
- ADR-0941；全量 Replay 见本提交。
