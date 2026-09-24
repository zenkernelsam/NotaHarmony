# 原版独立音频文件导入 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「Import File → 音频」链路的静态证据，
支撑 Phase 655。与 Phase 652/653/654 共用 `i58.c = */*` 选择器与
`yq8.f` 负载路由。

## 选择器与类型表

- `i58.java:6`：`new i58("*/*")`。
- `nj3.java`：音频类型表 —— `mp3("audio/mpeg")`、`mp4("audio/mp4")`、
  `aac("audio/aac")`、`wav("audio/wav")`、`aiff("audio/aiff")`、
  `m4a("audio/mp4")`。
- `yq8.java:35-37`：`uu5Var instanceof pu5 → return izi.M`。
- `pu5.java`：`File K`（临时文件）+ `long L`（时长毫秒）+
  `String M`（MIME）；`a()` 删临时文件。

## cv5 音频分支：临时复制 + 时长

`cv5.java`（约 80–160 行）：

```java
zu5 zu5VarF = jv5.f(jv5Var2, uri2, drfVar, ttfVarX, null, 24);  // 临时复制
File file2 = ((xu5) zu5VarF).a;
String strI = nj3Var.I;
if (strI.length() == 0 && (strI = fsi.I(jv5Var.a, uri)) == null) {
    strI = "audio/*";                          // MIME 回退链
}
String str = strI;
try {
    MediaMetadataRetriever r = new MediaMetadataRetriever();
    r.setDataSource(file2.getAbsolutePath());
    String meta = r.extractMetadata(9);        // METADATA_KEY_DURATION
    j = meta != null ? parsed : 0L;
} catch (IOException|IllegalArgumentException|IllegalStateException|
         RuntimeException e) {
    a.e(..., "Failed to retrieve audio duration", ...);
    j = 0;                                     // 任何失败兜底 0
}
return new nv5(new pu5(
    new o88(ttfVarX, nj3Var, nj3Var, drfVar.a, 0, false),  // 页数=0
    file2, j, str));
```

## izi.M：资产创建 + CREATE_RECORDING

`izi.java`（variant 3，约 182–262 行）：

```java
pu5Var = (pu5) uu5Var2;
objT = xj2.T(t13.K, new re0(file, str, pu5Var, p29Var, ttfVar, null, 0));
    // IO 线程建录音资产 → akb
return new te0(iaj.a(null, lvd.a1(uu5Var2.J.d, '.'), (akb) objT,
    0L, pu5Var.L, new xgb(i2)), 0);
    // te0 variant 0：xq9.a(wq9(yn2)) 单 op —— 不建页
```

- `lvd.a1(name, '.')`：文件名去最后后缀取 stem。
- `yn2.java` flatbuffer：字段4=`akb` 资产（required）、字段6=start、
  字段8=end、字段10=name、字段12=segments、字段14=color；
  校验「Start time must be before end time」「Segments must not
  extend beyond duration」。
- `zq9.java:18`：`mx7Var.put(npbVar.b(yn2.class), haa.CREATE_RECORDING)`
  —— CREATE_RECORDING op（type 5）。
- `iaj.a(null, stem, akb, 0L, duration, xgb)`：segments=null、
  start=0L、end=duration。
- 资产创建 IOException → 记 `Failed to create audio recording asset`
  + `ozb` 错误结果。

## Harmony 适配决策

1. **选择器**：`fileSuffixFilters` 追加
   `.mp3/.mp4/.aac/.wav/.aiff/.m4a`（nj3 音频表精确子集）。
2. **MIME**：后缀 → nj3 MIME 精确映射；未命中回退 `'audio/*'`
   （原版回退链 `nj3.I → fsi.I(uri) → "audio/*"` 的尾段）。
3. **时长**：`media.AVMetadataExtractor` + `fdSrc` 读 `duration`，
   任何失败兜底 `0`（对齐 `j=0`）。
4. **暂存**：`persistCapturedOriginalRecording` 需要真实路径 +
   stat —— 字节先落 `assets/pending/audio_import_*.tmp`，persist
   的 finally 删除（无论成败）；persist 前的失败手动 unlink。
5. **落库**：`importMutex` 内 `createNoteWithMeta`（0 页，
   hasRecordings=true）→ `persistCapturedOriginalRecording`
   （pending→final 资产 + CREATE_RECORDING op + markLocal）；
   异常 → `removeFailedImport`。
6. **时间戳**：原版 `start=0L/end=duration`；Harmony 本地录音写者
   校验 `startTime>0` 且 `endTime===startTime+duration` —— 记为
   导入时刻 `[now, now+duration]`（文档化差异）。
7. **页**：原版 `o88` 页数=0、`te0` 不建页 → Harmony 0 页；
   编辑器 `loadPages` 的 zero-page recovery 打开时补默认页
   （对齐原版空笔记 action row 的等价 UX）。

## 已知差异（fail-closed / 记录项）

- **startTime**：原版 0L（无捕获时刻）；Harmony 记导入时刻
  （本地 CreateRecording 写者的 start 语义 = 采集时间戳）。
- **segments/color**：原版 `yn2` 可携带 segments 与 `xgb` 颜色；
  Harmony 本地写者省略 segments、zIndex=0（与既有本地录音一致）。
- **MIME**：原版 MIME 嗅探链可识别容器内真实类型；Harmony 后缀
  映射（`.mp4` 视频文件会按 audio/mp4 导入 —— 与 nj3 表语义一致）。
- **时长**：Harmony `AVMetadataExtractor` 与 Android
  `MediaMetadataRetriever` 的格式覆盖略有差异；失败均回退 0。
