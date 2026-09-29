# ADR-0941 — 上传管线（oq1/wqf/d8d/q89）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `oq1` = 上传客户端：`b()`=uploadAppendedOps
  （`pv2.a` 串行锁）、createNote 校验首 op=CreatePage。
- `wqf` = Retrofit：POST `collab-api/note/{id}/append?siteId`
  与 `collab-api/note/create`（title/deviceId/noteId/
  createdAt=末 op clientTime）。
- `aa6.r0(List<uq9>)` → vt9 OpsBundle（c8d shm 16KB +
  `ree.a` per-op + `D(4)` 向量）→ `d8d`。
- `d8d extends nwb(RequestBody)`：octet-stream，
  `m()`= `bb.position(L); sink.write(bb)` 零拷贝，
  `close()` 释放 shm。
- 响应 `vyb`→`ys2.k`→**q89 NoteMutationResponse
  {noteId:utf 必需@f4, acks:vq9[]@f6}**；AssertionError
  →"Malformed NoteMutationResponse"→ozb。

## Harmony 决策

- 后端依赖，fail-closed：本地持久化正常，上传禁用。
- 协议格式完整记录，可复用；零拷贝语义可平移到
  `@ohos.net.http` ArrayBuffer。

## Parity 状态

fail-closed（无服务器）。

## 验证

- `d02-upload-pipeline.mjs`：21/21 通过。
