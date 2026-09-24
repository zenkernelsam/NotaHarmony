# ADR-0623 Office/RTF/Apple 文档导入 fail-closed（jv5 fca.f 转换漏斗）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：656
- 接续：ADR-0619/0620/0621/0622（文件导入系列）
- 证据：`docs/migration/evidence/original-office-file-import-jadx-2026-09-24.md`

## 背景

原版 `nj3` 类型表含十一种非图片/非音频/非纯文本文档：
`.doc/.docx/.ppt/.pptx/.ppsx/.xls/.xlsx/.rtf/.rtfd/.key/.pages`。
`i58.c` 选择器接受 `*/*`，`jv5` 状态机把它们全部送入
`fcaVar*.f(absolutePath, z39, …)` 加载调用（共 5 处），产出 `r8d`
PDFTron 文档后统一构造 `su5(o88(nj3.pdf, 源nj3类型, …), r8d, 页列表)`
——转换产物恒为 PDF，与 Phase 652 PDF 导入共用 `yq8.f` 的 `su5` 分支。
Office→PDF 转换发生在 PDFTron 引擎内部，原版 App 不自带转换实现。

## 决定

1. **结构性 fail-closed**：HarmonyOS PDFKit `pdfService` 只提供
   `loadDocument`（解析既有 PDF）与 `convertToImage`（PDF→图片），
   无 Office/RTF/Apple→PDF 转换 API；PreviewKit 仅预览不产出字节。
   没有可用转换引擎，故不实现该十一种类型的导入，也不伪装实现。
2. **选择器不收录**：`fileSuffixFilters` 维持
   `.note/.pdf` + 9 种图片 + `.txt` + 6 种音频，不加 Office/RTF/Apple
   后缀——与其让用户选中后必失败，不如在选择器层就不可选。
3. **二次防线**：经分享/Intent 等途径绕开选择器进入
   `importFromFile` 的同类文件，因扩展名不匹配任何已实现分支而落
   `importFromData`；非 `.note` ZIP/manifest → `CORRUPTED` 或
   `UNSUPPORTED_FORMAT` 返回，不会写出半成品笔记。
4. **登记方式**：专项 Replay 钉住「nj3 十一种类型证据 + jv5
   `fca.f → su5(nj3.pdf)` 转换漏斗 + 选择器排除 + 无转换路径 +
   importFromData 兜底」五条不变量。

## 后果

- `.docx` 等文件在原版可导入，Harmony 侧不可选、不可导入——
  差异已登记；若未来 Harmony 提供等价转换能力（如系统级
  Office→PDF 服务），可在 `importFromFile` 分发链中按同一
  `su5` 语义接入 PDF 管线复用 Phase 652 全部下游逻辑。
- `nj3` 全部 25 种类型至此均有去向：`.note/.nbn/.ntb`（既有
  归档导入）、`.pdf`（652）、9 种图片（653）、`.txt`（654）、
  6 种音频（655）、11 种 PDFTron 转换类型（本 ADR fail-closed）、
  `unknown`（原版亦 fail-closed）。
