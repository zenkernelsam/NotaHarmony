# Phase 1000 证据 — 缩略图上传（xqf）+ nr1 剩余依赖

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `xqf` = 缩略图上传 Retrofit

```java
interface xqf {
    @vi8                          // @Multipart
    @oy9("/images/thumbnails")    // POST
    Object a(@j7a("noteId") nwb noteIdPart,     // @Part 文本体
             @j7a("siteId") short siteId,
             @j7a("logicalTime") int logicalTime,
             @j7a wi8 thumbnailPart,            // MultipartBody.Part
             @me5("Accept") String accept,      // @Header
             ef2<? super mof>);                 // 返回 Unit
}
```

- 五元组 multipart：noteId(文本 RequestBody) +
  siteId + logicalTime（缩略图对应 op 时间戳）+
  thumbnail 二进制 part + Accept 头。
- 端点独立于 collab-api（裸 `/images/thumbnails`）。

## `nr1` 剩余构造依赖（补全 Phase 999）

| 字段 | 类型 | 实证 |
|------|------|------|
| c | `ssf` | `{q75 a, xrf b, vs4 c, pce d, sfb e}` —— 服务级
  组件（dispatcher+mutex+lazy），详情未展开 |
| d | `qr1` | `{pce a, pce b}`，`qr1(Context, dbe)` —
  路径 lazy 对（随 `dbe` ops 根定位） |
| e | `jl3` | `{pce a, pce b, sfb c}`，`jl3(cx6)` —
  lazy×2 + Mutex（另一同步子组件） |
| f | `sxa` | `{Context a}` —— 最小 context 持有者 |
| g | `v2f` | 接口 `{t2f a()}` —— **时钟/时间源**
  （`t2f.a(j)` = Duration/mark；nr1.b 用它计时） |

- `we2 we2VarA = s01.a(dh3.a)` —— 编排作用域取自
  `cx6`（应用级 CoroutineScope 提供者）。

## 同步 API 全景（Phases 997-1000 合订）

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `collab-api/note/create` | 建笔记（title/deviceId/noteId/createdAt + vt9 body） |
| POST | `collab-api/note/{id}/append?siteId` | 追加 ops（vt9 body） |
| GET | `collab-api/note/{id}/sync?clientMaxServerTime&clientOpCount` | 增量拉取 |
| GET | `collab-api/note/{id}/bundle?deviceId` | 整包拉取 |
| POST | `/images/thumbnails` | 缩略图 multipart |
| POST | `/auth/nonce`、`/google/sign-in`、`/microsoft/sign-in` | `f8c` 鉴权（GMS 依赖） |
| POST | `/stripeConsumer/*` | `wvd` 订阅（不迁移） |

## HarmonyOS 决策

- `xqf` 同属后端依赖 fail-closed；Harmony 缩略图
  仅本地生成（PixelMap）。
- `v2f` 时钟语义可平移到 `systemDateTime`/`hilog` 计时。

## 产出

- fixture `d02-thumbnail-upload.mjs`（12 断言）。
- ADR-0944；中文报告。
