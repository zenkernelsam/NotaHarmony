# Phase 664 证据：原版 `/app/note/<id>` 深链（notability.com → 打开本地笔记）

日期：2026-09-24
关联：ADR-0631；前置 Phase 661（共享入口 want 队列）、
Phase 663（快捷方式 want 队列）

## 原版实现（decompiled_1.0.3）

### AndroidManifest.xml —— 深链 intent-filter

`resources/AndroidManifest.xml`（MainActivity 首个 filter）：

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="http"/>
    <data android:scheme="https"/>
    <data android:host="notability.com"/>
    <data android:host="*.notability.com"/>
    <data android:pathPrefix="/authlink"/>
    <data android:pathPrefix="/app/note"/>
    <data android:path="/event/learn-from-home"/>
    <data android:path="/event/learn-from-home/"/>
    <data android:path="/event/plus25"/>
    <data android:path="/event/plus25/"/>
</intent-filter>
```

### py2 —— 深链谓词与解析器

`defpackage/py2.java`：

- `a = lvd.S0(lvd.e1("/app/note", '/'), ...)` → 段列表 `["app","note"]`。
- `b = m18.m0("event", "learn-from-home")`、`c = m18.m0("event","plus25")`。
- `f(uri)`：`(scheme==http || scheme==https) && host!=null &&
  (host.equals("notability.com") || svd.f0(host, ".notability.com"))`。
- `a(uri)`：`f(uri)` 且 `pathSegments.size()==a.size+1` 且前缀相等 —
  恰为 `/app/note/<id>`。
- `b(uri)`：取第 `a.size` 段 → `wtf.f(str)` → `ttf` 笔记 ID。
- `d(uri) = e(uri) || g(uri)`：`e`=`["event","learn-from-home"]`，
  `g`=`["event","plus25"]`。
- `c(uri)`：`/authlink` 经 `bz2.L` 模式表解析出
  `yy2(userId, linkUUID)` = `VerifyLink`。

### m18.r0 / ug5.c —— 笔记 ID 文本格式

`defpackage/m18.java:2875` `r0(str)`：`length==32` 时把前 16 个
十六进制位折叠成 `j`、后 16 个成 `j4` 两个 long → `ttf`；
每位查 `ug5.c` 表，查不到即 `xag.e(i, str, "a hexadecimal digit")`。

`defpackage/ug5.java`：`c` 表仅登记 `0-9`、`a-f`、`A-F`（Kotlin
hex 解析同表）。→ 原版笔记 ID 文本为**恰好 32 个十六进制位**。

### hv7.i —— 深链消费入口

`defpackage/hv7.java:58`：

```java
if (ba6.o(intent.getAction(), "android.intent.action.CREATE_NOTE")
    || fag.h0(intent) != null
    || ((data = intent.getData()) != null && py2.d(data))) {
    this.Q.j = true;
}
xj2.A(h(), null, null, new kx(10, (ef2) null, intent, this), 3);
```

`py2.d`（事件链接）置 `Q.j` 启动标记；`/app/note` 与 `/authlink`
由 `kx` 协程按 intent 分发消费。`kx.invokeSuspend` 主体 JADX
未能完整反编译（与 `re0`/`yq8.e` 同类 opaque），笔记链接的具体
消费（打开笔记 / 未命中时后端同步取回）无直接指令级证据 —
`py2.b` 存在的目的即把链接段解析为 `ttf`，打开本地笔记是唯一
合理语义；未命中路径涉及订阅后端同步，登记 fail-closed。

## Harmony 对齐

| 原版 | Harmony |
|------|---------|
| manifest VIEW+BROWSABLE+autoVerify，`notability.com`/`*.notability.com`，`pathPrefix /app/note` | `module.json5` skills 增挂独立 skill 对象：`entity.system.browsable` + `ohos.want.action.viewData` + `uris:[{scheme:https,host:notability.com,pathStartWith:app/note},{scheme:http,…}]` |
| `py2.f` host/scheme 谓词 | `DeepLinkIngress.isNotabilityHost`（`notability.com` 或 `.notability.com` 结尾，http/https） |
| `py2.a` 恰 3 段 `["app","note",id]` | `parseDeepLinkNoteId`：`segments.length===3 && [0]==='app' && [1]==='note'` |
| `m18.r0`+`ug5.c` 恰 32 hex | `isDeepLinkNoteId`：`length===32` 且每位 ∈ `0-9a-fA-F` |
| `hv7.i` → `kx` 协程 | `NoteAbility.onCreate/onNewWant` → `enqueueDeepLinkWant` → `LibraryPage.onPageShow` → `drainDeepLinkIngress` |
| `py2.b` → `ttf` → 打开笔记 | `resolveDeepLinkNoteId`：`note_meta.id` 直查（`deleted_at IS NULL`）→ 未命中查 `note_sync_metadata.legacy_id`（导入改号副本保留原 ID）→ 命中 `pushUrl NotePage` |
| 未命中 → 订阅后端同步取回（kx 内，opaque） | `deep_link_note_missing` toast（fail-closed 登记） |

## fail-closed 登记

1. **`*.notability.com` 子域**：Harmony `uris.host` 只接受单一域名，
   不支持通配；`uris` 仅声明 `notability.com`。解析器内部仍保留
   `py2.f` 的子域接收语义（若系统经其它途径投递子域 want 仍可
   解析）。
2. **AppLinking `domainVerify`**：浏览器直接投递需在
   `notability.com` 托管 applinking 关联文件 —— 非本工程可控域。
   未开启 `domainVerify`；显式 want（`aa start -U`、open-with）
   仍能按声明路由到本应用。
3. **`/authlink` → `VerifyLink(userId, linkUUID)`**：账号后端校验
   流，订阅域 —— 不声明不实现。
4. **`/event/learn-from-home`、`/event/plus25`**：营销事件链接
   （`py2.d` → `Q.j`），无本地语义 —— 不声明不实现。
5. **本地未命中**：原版经 `kx` 走订阅后端同步取回；Harmony 无
   对应后端，弹 `deep_link_note_missing` toast 并停在资料库。
6. **回收站笔记**：`deleted_at` 非空视为未命中（与资料库投影
   排除语义一致；原版对回收站目标的深链行为无证据）。
