# Phase 661 证据：外部共享/打开 PDF 入口（fag.h0 VIEW/SEND intent）

日期：2026-09-24
关联：ADR-0628；前置 Phase 652（PDF 导入）、660（密码处理）

## 原版实现（decompiled_1.0.3）

### AndroidManifest intent-filter

`MissingNativeLibraryActivity`（launcher 活动）注册：

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category ...DEFAULT/><category ...BROWSABLE/>
  <data android:scheme="content"/><data android:scheme="file"/>
  <data android:mimeType="application/pdf"/>
</intent-filter>
<intent-filter>
  <action android:name="android.intent.action.SEND"/>
  <category ...DEFAULT/>
  <data android:mimeType="application/pdf"/>
</intent-filter>
```

### fag.h0 — intent → URI 提取

`defpackage/fag.java`（2507 起）：

```java
public static final Uri h0(Intent intent) {
    // SEND + type=="application/pdf" → EXTRA_STREAM 中的 Uri
    // VIEW + data.scheme∈{content,file} → intent.getData()
    // 其余 → null
}
```

### hv7.i — 启动标记 + 导入协程

`defpackage/hv7.java:58`（launcher ViewModel）：

```java
public final void i(Intent intent) {
    if (CREATE_NOTE || fag.h0(intent) != null || py2.d(data)) {
        this.Q.j = true;           // 启动即带 ingress 标记
    }
    xj2.A(h(), null, null, new kx(10, null, intent, this), 3);  // 导入协程
}
```

共享 URI 经 `kx(10)` 协程进入与内建选择器相同的 `jv5` 嗅探分发
管线，物化为独立笔记（`rv5`/`su5`/`nv5` 语义）。

## Harmony 对齐实现

| 原版 | Harmony |
|---|---|
| manifest VIEW/SEND application/pdf | module.json5 skills：viewData/sendData/sendMultipleData + `uris:[{scheme:file,type:application/pdf}]` |
| Activity onCreate/onNewIntent 收 intent | NoteAbility `onCreate(want)`/`onNewWant(want)` |
| fag.h0 提取 EXTRA_STREAM/data URI | `enqueueSharedWantUris`：viewData → `want.uri`；sendData/sendMultipleData → `parameters['ability.params.stream']`（数组逐项） |
| hv7.i → kx 协程导管线 | `LibraryPage.onPageShow` → `drainSharedIngress` → `importSharedUris` → `importPickedFilesStandalone`（同一读取+嗅探+逐文件物化） |
| 成功后库中出现导入笔记 | 打开最后一篇导入笔记（router.pushUrl） |
| ou5 密码流程 | `pdfPasswordPrompt` 透传（Phase 660） |

## 设计取舍

1. **进程内队列**：want 在 `onCreate/onNewWant` 到达早于 UI 就绪 →
   `SharedFileIngress` 以模块级数组暂存，`onPageShow` 统一 drain
   （`splice` 原子清空），避免丢 want 也避免重复导入。
2. **复用 rv5 分发表**：共享 URI 与多选导入同一
   `readPickedFile`+嗅探+逐文件物化路径——原版 `h0` 下游同样汇入
   `jv5` 分发，无第二套语义。
3. **skill uri 收窄到 application/pdf**：与原版 manifest 的
   mimeType 声明一致；其余类型经内容嗅探仍可路由（同原版 h0 不验
   MIME 只验 scheme 的宽松行为）。
4. **页面销毁/未激活**：`importSharedAndOpen` 沿 `importAndOpen`
   的 `pageActive`/`createBusy`/`lifecycleGeneration` 守卫。

## 验证

- Replay `d05-original-shared-pdf-ingress.mjs`：19 断言全绿。
- 全量 Desktop Replay 545 → 546 全绿。
- `note@ohosTest` / `note@default` 双 HAP clean 构建成功。
