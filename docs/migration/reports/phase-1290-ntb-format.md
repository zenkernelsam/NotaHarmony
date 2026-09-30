# Phase 1290 报告 — .ntb 包格式 + 文件注册表（里程碑）

## 完成内容

- `.ntb` = **ZIP 笔记包**（`yk9`/`x59` ZipEntry/
  putNextEntry + `ax7` ManifestData Kotlin-serializable
  manifest + `flatbuffers.a` 笔记 ops + 媒体资产）；
  `nj3` = 32-格式 MIME 注册表（doc/docx/ppt/xls/key/
  pages/pdf/txt/rtf + png/heic/mp3/m4a + **nbn/note/ntb**
  笔记包变体）—— Notability 可移植笔记格式 +
  导入/导出文件类型核心。

## 产出

- evidence `phase-1290-ntb-format.md`
- fixture `d02-ntb-format.mjs`（10/10）
- ADR-1234
