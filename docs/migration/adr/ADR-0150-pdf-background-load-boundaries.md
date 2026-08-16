# ADR-0150: PDF 背景加载边界

## 决策

`PdfBackgroundLoader` 作为独立 API 边界，在查询资产和调用 PDFKit 前拒绝非法的 `totalPageCount`、`pageInAsset` 与 `fileSize`。本地文件必须是普通文件且实际大小与 PDF metadata 一致。解析后只读取一次 PDFKit 页数，并要求它是正安全整数、等于 metadata 总页数且包含目标页。

## 原版依据

1.0.3 `ddg.java:f(sw9)` 明确要求 `totalPageCount > 0`，且 `pageOffset + pagesConsumed` 不得超过总页数。移植侧模型层已有完整区间校验；loader 仍需自行保护 native PDF API，不能假设所有调用者都经过模型反序列化入口。

## 原因

原实现只拒绝 `pageInAsset >= getPageCount()`，负数和非整数仍可传入 `getPage()`；异常或不稳定的 PDFKit 页数也会传播。本地文件内容被截断或替换时，仅比较数据库 metadata 无法发现落盘文件与原始资产声明不一致。

## 验收

静态 replay 检查输入边界、文件 stat、单次页数读取及调用顺序。真实损坏 PDF、超大 PDF 与 PDFKit 资源释放仍需设备运行态验收。

## Phase 256 生命周期补正

ADR-0234 发现本 ADR 当时只验证 document 释放，遗漏 SDK 明确要求的 `PdfPage.release()`。loader 现显式保存
page 句柄，并在所有路径先释放 page、再释放 document；两次清理分别捕获错误。静态所有权缺口已关闭，
真实连续切页/缩略图的 native 内存曲线仍保留为设备验收项。

## Phase 257 可见区栅格补正

ADR-0235 为 loader 增加独立 `PdfRasterRequest` 边界：纯逻辑 plan 在进入 PDFKit 前验证 page/visible/output
geometry，生成 bottom-origin Points matrix 和有 hard cap 的输出尺寸。区域 API 失败只回退整页 PixelMap，
不会绕过本 ADR 的 metadata、文件大小、页数和 page index 校验。完全不可见页面可返回 READY/null；恢复可见后
由 viewport coverage 重新请求。真实 PDFKit matrix 边缘、内建 page rotation 和内存峰值仍需设备验收。
