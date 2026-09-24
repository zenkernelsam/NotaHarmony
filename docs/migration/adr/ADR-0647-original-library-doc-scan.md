# ADR-0647：原版 LIBRARY_DOC_SCAN 移植（VisionKit DocumentScanner）

- 状态：已接受
- 阶段：Phase 680

## 背景

原版 `ac4.a0 = LIBRARY_DOC_SCAN(15)` 门控资料库「+」菜单中的
「Document Scan」入口（`cd.java` case 0 序位尾位），点击后拉起
Google ML Kit 文档扫描器，结果经 `ib7/pk9.onDocScanned(Uri, title,
success, failure)` 物化为新笔记（标题 `scanned_document_title`）并打开。
ML Kit 依赖 Google Play services，HarmonyOS 上不可用。

## 决定

1. **移植而非 fail-closed**：HarmonyOS VisionKit `DocumentScanner`
   组件（API 12+）能力等价——拍摄、边缘裁切、滤镜增强、编辑
   （旋转/删除/重拍）、图库导入、多页（≤50）、PDF 产出。
2. **等价门控**：原版 `lc4.a(ac4.a0)` 远程旗标 → Harmony
   `canIUse('SystemCapability.AI.Component.DocScan')` 系统能力探测；
   无能力的设备不渲染入口，与原版 flag-off 同语义。
3. **承载方式**：`bindContentCover` 全屏 cover 承载组件（VisionKit
   明确扫描界面不得被其他组件/窗口遮挡）；下滑关闭 = 取消（`-1` 静默）。
4. **配置对齐**：`supportType=[DOC]`、`saveOptions=[PDF]`（原版
   `onDocScanned` 消费 PDF Uri）、`isShareable=false`（扫描结果只进
   新建笔记管线，不经系统分享）、`maxShotCount=50`（SDK 上限；原版
   ML Kit 页数上限随 `wc.invoke` 未解出）。
5. **结果管线**：`code=200` → `NoteImporter.importScannedDocument`
   （薄封装 `importFilesIntoSingleNewNote`，即原版 sv5
   CreateSingleNewNote 语义）→ 新笔记标题 =
   `scanned_document_title` + 时间戳 → 刷新列表 → `router.pushUrl`
   打开（对应原版 `onShowNoteInFolder`）。`code=-1` 静默；其余 →
   `doc_scan_failed` toast。

## 差异 / 未覆盖

- 空笔记页 Scan（`u49.java`，结果并入当前笔记）依赖尚不存在的
  空笔记快捷动作面，登记为后续 Phase 候选。
- 原版 `%1$s` 标题占位实际填充值未解出；采用 `M/D H:MM` 本地时间戳。

## 验证

- Replay `d02-original-library-doc-scan.mjs`：27 断言全绿；
  全量套件 564/564；`note@ohosTest`、`note@default` 双 HAP 构建成功。
- 真机扫描界面交互属设备验证项，已入真机清单补遗。
