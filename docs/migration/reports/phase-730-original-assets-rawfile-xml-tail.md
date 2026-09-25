# Phase 730 中文报告：assets/+res/raw+res/xml 尾部收口登记

## 范围

APK `assets/` 154 项 + `res/raw/` 10 项 + `res/xml/` 10 项逐项
归属核对——资源审计收官阶段（文档级）。

## 原版证据

见 `docs/migration/evidence/original-assets-rawfile-xml-tail-jadx-2026-09-25.md`。

要点：`assets/` 大头为 MyScript HWR/数学引擎内部件（conf 语法、
glmath 字族、resources/*.res 模型 ≈50 项）与内嵌 gocr OCR 模型
（≈60 项）；`ConversionRates.csv` 解码为 `sq2`→`rm0`/`j6b` 的
Play Billing 价格→USD 归因换算（计费分析管道，非用户功能）；
`NoteAsset*Worker`/`LibraryStateUploaderWorker`/`ExportSweepWorker`
为云同步 WorkManager。`res/xml` 中 `remote_config_defaults.xml`
为 ac4 旗标注册表（ADR-0658 已审语义）的 Firebase 默认载体。

## 归属结论

- 已移植/等价：widget_info ×5→forms_config（P726）、filepaths→
  fileUri 分享（P729）、emoji 语料差异已登记。
- 边界登记：MyScript/MLKit/PDFTron/YouTube/Inky/Learn Rive/同步
  workers/计费分析 CSV/平台件（splits0/PSL/baseline.prof/m3）。
- 无代码变更、无新增真机项。

## 验证

- `d02-original-assets-rawfile-xml-tail.mjs` 专项全绿。
- 全量 Desktop Replay 全绿；双 HAP clean 构建成功（文档级阶段）。
- 至此 res/+assets/+manifest 三大资源域审计闭合；后续转入 JADX
  `defpackage` 逻辑面长尾取证。
