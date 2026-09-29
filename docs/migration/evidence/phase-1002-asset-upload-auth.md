# Phase 1002 证据 — 资产上传（vqf）+ 鉴权（f8c）+ DeviceId（je3）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `vqf` = 资产直传（GCS 签名 URL）

```java
interface vqf {
    @py9                          // POST
    Object a(@irf String url,                 // @Url 动态地址
             @nz0 nwb body,                   // @Body 资产字节
             @me5("content-md5") String md5,  // @Header
             @me5("x-goog-content-length-range") String range,
             ef2<? super vyb>);               // 返回 ResponseBody
}
```

- `@irf` = `@Url`（服务器回签的 GCS 签名 URL）。
- `content-md5` + `x-goog-content-length-range` =
  Google Cloud Storage 签名直传头部 → **资产走 GCS
  直传，不经 collab-api**。
- body 仍是 `nwb`(RequestBody)；资产源即 `wa0`/
  `pa0` 族引用的文件。

## `f8c` = 鉴权端点

```java
@oy9("/google/sign-in")    Object a(@nz0 d8c, ef2<ryb<e8c>>)
@oy9("/microsoft/sign-in") Object b(@nz0 d8c, ef2<ryb<e8c>>)
@oy9("/auth/nonce")        Object c(ef2<ryb<a8c>>)
```

- `d8c` = 登录请求体（idToken 等）；
  `e8c` = 会话响应；`a8c` = nonce 响应；
  `ryb<T>` = 响应包装。
- google/microsoft 双 OAuth + nonce（防重放）。

## `je3` = DeviceId 值类

```java
@fyc(with = qe3.class)   // kotlinx Serializable
final class je3 { ttf a; }   // = UUID
static ttf a() {
    byte[16] buf;
    coc.a.nextBytes(buf);    // SecureRandom
    buf[6] = (buf[6]&15)|64; // version 4
    // variant bits 同设 → RFC4122 v4 UUID
}
```

- 用法：`ko.o` 的 `bundle?deviceId=je3.a`、
  `wqf.b` createNote 的 `deviceId` 参数。

## 同步 API 全图（Phases 997-1002 终版）

| 方法 | 端点 | 用途 |
|------|------|------|
| POST | `/auth/nonce` | 重放保护 nonce |
| POST | `/google/sign-in` `/microsoft/sign-in` | OAuth 登录 |
| POST | `collab-api/note/create` | 建笔记+首 ops |
| POST | `collab-api/note/{id}/append` | op 追加 |
| GET | `collab-api/note/{id}/sync` | 增量同步 |
| GET | `collab-api/note/{id}/bundle` | 整包下载 |
| POST | `/images/thumbnails` | 缩略图 multipart |
| POST | *签名 URL*（vqf） | 资产 GCS 直传 |
| POST | `/stripeConsumer/*` | 订阅（不迁移） |

## HarmonyOS 决策

- `vqf`/`f8c` 全部 fail-closed（无服务器；GMS 依赖）。
- `je3` DeviceId 语义保留：`getRandomUUID` 等价
  RFC4122 v4（Harmony `util.generateRandomUUID`）。

## 产出

- fixture `d02-asset-upload-auth.mjs`（14 断言）。
- ADR-0946；中文报告。
