# Phase 997 证据 — 上传管线（oq1 / wqf / aa6.r0 / d8d / ys2.k / q89）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 上传客户端 `oq1.java`

`oq1` = collab 同步上传客户端：

- `b(ttf noteId, List<uq9> ops, ff2)` = **uploadAppendedOps**：
  `pv2.a("uploadAppendedOps")` 串行锁 → `aa6.r0(list)`
  产 vt9 OpsBundle → `wqf.a/b` Retrofit 调用 →
  `ys2.k(vyb, "appendOps"/"createNote")` 解包响应。
- createNote 分支：先校验首 op 为 CreatePage 且
  pageCount>0，否则 `IllegalArgumentException(
  "CreatePage op with positive pageCount not found")`
  经 `yn7` 记录并包 `ozb` 返回。
- 请求参数：`title`、`deviceId`、`noteId`（UUID str）、
  `createdAt` = 最后一 op 的 `uq9.k()` clientTime。

## Retrofit 接口 `wqf.java`（完整仅两方法）

```java
@py9("collab-api/note/{id}/append")          // POST
Object a(@j8a("id") String noteId,
         @b7b("siteId") short siteId,
         @nz0 nwb body, ef2<? super vyb>);

@oy9("collab-api/note/create")               // POST
Object b(@b7b("title"), @b7b("deviceId"),
         @b7b("noteId"), @b7b("createdAt") long,
         @nz0 nwb body, ef2<? super vyb>);
```

- `@py9`/`@oy9` = POST 路径注解；`@j8a` = @Path；
  `@b7b` = @Query；`@nz0` = @Body。
- 端点：`collab-api/note/{id}/append?siteId=` 与
  `collab-api/note/create`。
- 返回 `vyb` = okhttp3.ResponseBody（原始字节）。

## 请求体 `d8d extends nwb implements AutoCloseable`

`nwb` = okhttp3.RequestBody（`a()`=contentLength、
`b()`=contentType、`m(o51)`=writeTo、`c()`=isDuplex）。
`d8d` = SharedMemory-backed 请求体：

- 字段：`c8d J`（shm 分配器）、`ByteBuffer K`、
  `int L`（数据起始位置）、`long M`（内容长度）、
  `h58 N = "application/octet-stream"`。
- `m(o51)`: `K.position(L); o51.write(K)` —
  **mmap→网络零拷贝写**。
- `close()`: `J.close()` 释放 shm。

## OpsBundle 生产 `aa6.r0(List)`

- `new a(c8d, c8d.l2(16384))` — shm 16KB 初始缓冲。
- `sg5.e()` CAS + `sg5.d()/c()` 双缓冲偏移列表
  （与 q4j/x6j 同一模式）。
- 逐 op `ree.a` → `D(4,size,4)` ops 向量 → r29/`vt9`
  根 → 包成 `d8d` 返回。

## 响应解码 `ys2.k(vyb, String opName)`

- `vyb.a()` → ByteBuffer → LE → `q89` 根。
- `pzb.a` 错误检查：Error/CancellationException 直接
  抛出；其余异常包 `ozb` 返回。
- `AssertionError` → `yn7.SERVER_PERSISTENCE` 记
  `"Malformed NoteMutationResponse"`（附 opName
  lambda `ft0(9,e,str)`）→ `ozb`。

## 响应表 `q89` = NoteMutationResponse

```java
final class q89 extends cee implements ka4
```

- `l()` @f4 = **noteId:utf REQUIRED**
  （`o14.i("No value for (required) field noteId")`）。
- `k()` @f6 = acks 向量长度；`j(vq9,i)` 元素访问器。
- `lv2.t(q89)` = acks→`List<vq9>` 物化。
- `toString`: `"NoteMutationResponse(noteId=..,acks=..)"`。
- 实现 `ka4`（validation marker，`a()`=null）。

## 管线总结

```
ClientOp 行 → nr1 收集 → oq1.b
  → aa6.r0: [uq9]* → vt9 FlatBuffer (shm)
  → d8d RequestBody (octet-stream, 零拷贝)
  → wqf.a/b Retrofit → collab-api
  → vyb bytes → ys2.k → q89{noteId, acks:vq9[]}
  → acks 写回 SyncedOpMetadata 校验和/偏移
```

## HarmonyOS 决策

- 上传管线整体**后端依赖**：无 collab-api 服务器，
  Harmony 版保持 fail-closed（本地持久化正常、上传
  禁用）。协议格式（vt9/q89/nwb）已完整记录，未来
  若接自建同步可原样复用。
- `d8d` 零拷贝语义可平移到 `@ohos.net.http` 的
  ArrayBuffer 直传。

## 产出

- fixture `d02-upload-pipeline.mjs`（18 断言）。
- ADR-0941；中文报告。
