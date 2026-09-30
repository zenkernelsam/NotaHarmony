# Phase 1290 证据 — .ntb 包格式 + nj3 文件类型注册表（里程碑）

来源：`defpackage/{nj3,yk9,x59,ax7,dv5,jv5}.java` +
`data/library/state/ntb/MissingAssetsException`。

## `.ntb` = **ZIP 笔记包**

```java
yk9/x59:  ZipEntry + putNextEntry + new Zip(Out|In)putStream
          + BufferedStreams + com.google.flatbuffers.a
ax7:      .ntb + ManifestData（Kotlin @Serializable manifest）
dv5/jv5:  jv5.f(uri, drf, ttf, "ntb", 16); nj3.ntb
          → 导出/导入管线
```

→ `.ntb` = ZIP 归档 = `ManifestData`（元数据 manifest）+
**FlatBuffers 编码的笔记 ops** + 媒体资产 ——
Notability 笔记的可移植包格式（导出/分享/备份）。

## `nj3` = **文件格式/MIME 注册表**（导入/导出枚举）

```
doc docx ppt pptx ppsx xls xlsx          // Office 导入
pdf                                       // PDF
txt rtf rtfd                              // 文本
nbn note ntb(application/octet-stream)   // 笔记包变体
png jpg jpeg webp tif tiff gif heif heic  // 图像
mp3 mp4 aac wav aiff m4a                 // 音视频
key pages                                 // Apple iWork
unknown
```

`{String I mime}` + 反查 `LinkedHashMap K`（mime/ext→
nj3）。

## `MissingAssetsException` = `.ntb` 解包资产缺失。

## 语义

**笔记可移植格式** —— `.ntb` ZIP{manifest+FlatBuffers
ops+assets}；`nj3` 注册表驱动导入（Office/PDF/图像/
音频/iWork→笔记）与导出（→ntb/pdf/txt/rtf）——
文档交换格式核心。

## Harmony 决策

`.ntb` ZIP+FlatBuffers → Harmony `ZipFile`/`@kit`+手写
FlatBuffers；`nj3` MIME 注册表 → Harmony `enum
FileFormat{mime}` —— 包格式+导入/导出语义保真。

## 产出

- fixture `d02-ntb-format.mjs`（10 断言）。
- ADR-1234；中文报告。
