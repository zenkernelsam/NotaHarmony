# ADR-0909 — `q4j` r29 NoteBundle 写器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`q4j.c` = NoteBundle 8 字段写器：ops 向量先经 `ree.a`
逐 op 序列化（**`sg5.e()` CAS + c()/d() 双缓冲偏移表**
实现嵌套写重入安全），逆序 D(4,i,4)；f0=noteId utf、
f1=legacyId(opt)、f2=editorSite、f3=editorUserId、
f4=createdAt、f5=creatorUserId、f6=ops、f7=schemaVersion=
rgc.a。**required = f0+f3+f6**（z(iN,4/10/14)）——与 906
读侧逐槽镜像。

## Harmony 决策

字段序+required 已对齐（906 Replay）；CAS 重入语义为
实现细节，等价正确性即可。

## Parity 状态

等价。

## 验证

- `d02-notebundle-writer.mjs`：21/21 通过。
- 全量 Replay 838 文件绿，见 Phase 965 提交。
