# ADR-0150: PDF 背景加载边界

## 决策

`PdfBackgroundLoader` 作为独立 API 边界，在查询资产和调用 PDFKit 前拒绝非法的 `totalPageCount`、`pageInAsset` 与 `fileSize`。本地文件必须是普通文件且实际大小与 PDF metadata 一致。解析后只读取一次 PDFKit 页数，并要求它是正安全整数、等于 metadata 总页数且包含目标页。

## 原版依据

1.0.3 `ddg.java:f(sw9)` 明确要求 `totalPageCount > 0`，且 `pageOffset + pagesConsumed` 不得超过总页数。移植侧模型层已有完整区间校验；loader 仍需自行保护 native PDF API，不能假设所有调用者都经过模型反序列化入口。

## 原因

原实现只拒绝 `pageInAsset >= getPageCount()`，负数和非整数仍可传入 `getPage()`；异常或不稳定的 PDFKit 页数也会传播。本地文件内容被截断或替换时，仅比较数据库 metadata 无法发现落盘文件与原始资产声明不一致。

## 验收

静态 replay 检查输入边界、文件 stat、单次页数读取及调用顺序。真实损坏 PDF、超大 PDF 与 PDFKit 资源释放仍需设备运行态验收。
