# 原版 Office/RTF/Apple 文档导入 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「Import File → Office/RTF/Apple 文档」链路的
静态证据，支撑 Phase 656（fail-closed 登记）。与 Phase 652 的 PDF 导入共用
`fca.f → r8d → su5` 管线，区别在于源类型不是 PDF，转换由 PDFTron 完成。

## 类型表：nj3 的十一种 PDFTron 转换类型

`nj3.java` 声明（`decompiled_1.0.3/sources/defpackage/nj3.java`）：

```java
doc("application/msword"),
docx("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
ppt("application/vnd.ms-powerpoint"),
pptx("application/vnd.openxmlformats-officedocument.presentationml.presentation"),
ppsx("application/vnd.openxmlformats-officedocument.presentationml.slideshow"),
xls("application/vnd.ms-excel"),
xlsx("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
rtf("text/rtf"),
rtfd,
key("application/vnd.apple.keynote"),
pages("application/vnd.apple.pages"),
```

选择器 `i58.java` 接受 `*/*`，`nj3.I`/`fsi.I` 按 MIME/扩展名识别上述类型。

## 转换漏斗：jv5 → fca.f → su5(nj3.pdf)

`jv5.java` 中 `fcaVar*.f(absolutePath, new z39(file, 5), …)` 共 5 处加载调用
（233/536/650/650 附近 ev5/bv5 状态机分支），每处成功后统一构造：

```java
su5 su5Var = new su5(new o88(ttfVar, nj3.pdf, nj3Var3, drfVar3.b(),
  ((ArrayList) adaVar2.a()).size(), true), (r8d) objT, adaVar2.a());
```

- `fca extends via`（`via.f` 是协程加载框架，`fca.e` 负责清理临时文件）；
  `fca.f` 产出 `r8d`（PDFTron 文档句柄）。
- `o88` 第一参恒为 `nj3.pdf`（笔记媒体类型），第三参 `nj3Var3` 保留源类型
  （doc/docx/…），即**转换结果总是 PDF 文档**。
- `yq8.java`：`uu5Var instanceof su5` 走 PDF reducer——Office/RTF/Apple
  导入与 Phase 652 PDF 导入下游完全同构。

## 结论

原版对 `.doc/.docx/.ppt/.pptx/.ppsx/.xls/.xlsx/.rtf/.rtfd/.key/.pages`
的导入依赖 PDFTron 的 Office→PDF 转换引擎（`fca.f` 内部）。转换产物是
`r8d` PDF 文档，此后与 PDF 导入共用 `su5` 负载与 `o88(nj3.pdf)` 描述符。

HarmonyOS PDFKit `pdfService` 仅提供 `loadDocument`（解析/渲染既有 PDF）与
`convertToImage`（PDF→图片），**没有** Office/RTF→PDF 转换 API；PreviewKit
`filePreview` 只能预览不能产出字节。故该十一种类型在 Harmony 上结构性地
不可等价实现，Phase 656 登记 fail-closed：
`fileSuffixFilters` 不收录这些后缀；经分享/Intent 进入的同类文件落入
`importFromData` 的 ZIP/manifest 校验，非 `.note` 即 `CORRUPTED`/
`UNSUPPORTED_FORMAT` 返回。
