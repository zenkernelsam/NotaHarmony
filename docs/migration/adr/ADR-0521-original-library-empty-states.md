# ADR-0521 — 原版库分区/文件夹空态

状态：Accepted（Phase 549）

## 背景

原版 `hf0` 按 `yw3` 描述符渲染分区/文件夹专属空态（图标+标题+正文），
文件夹无标题、有子文件夹时计数；Harmony 仅 FAVORITES 专属空态，其余
统一 `no_matching_notes`。

## 决策

1. 四个帮助函数按 folder/section 分派：ALL_NOTES→"Let's get started!"
   +引导正文；RECENT/FAVORITES/UNFILED→各自 title+body；文件夹→
   `empty_folder_body` 或带子项计数正文（子文件夹数+0 笔记）。
2. 搜索激活时保留通用无结果文本（登记适配）。
3. 图标用字形替代 xxlrg 矢量；复数计数因 SDK 无同步 plural API 改
   双正文变体（1 folder / N folders）。

## 验证

`d02-original-library-empty-states.mjs` 23/23；全套 444/444；
`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
