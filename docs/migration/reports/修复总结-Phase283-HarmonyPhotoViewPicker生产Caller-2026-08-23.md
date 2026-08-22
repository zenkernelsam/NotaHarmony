# Phase 283 修复总结：Harmony PhotoViewPicker 生产 Caller

日期：2026-08-23（Asia/Shanghai）  
状态：已完成静态生产接线与验证；真实设备 picker/格式矩阵仍开放。

## 目标

Phase 282 完成了 URI ingress 边界，但 `commitOriginalImageInsert()` 仍没有生产 caller。本阶段接入现行
`photoAccessHelper.PhotoViewPicker`、编辑器 Photo 入口和多图有序持久化，不启动设备或 Hypium。

## 实现

- 新增 `OriginalPhotoPickerCaller.ets`：
  - import 来自 `@kit.MediaLibraryKit`；
  - 使用 `PhotoViewMIMETypes.IMAGE_TYPE` 和 `maxSelectNumber = 500`；
  - 保持 `photoUris` 返回顺序；
  - 选择器可注入，便于静态 fixture。
- 工具栏新增 Photo；compact 菜单同步暴露。
- `NotePage → NoteCanvasView` 使用独立信号传递入口事件。
- 画布增加 `photoImportBusy`，避免并发选择/导入与持久化重入。
- 每张 ingress 结果按顺序构造 persistence plan：normalized bytes/MIME/dimensions、页面尺寸、当前 zoom
  与逐张偏移的 anchor。
- 复用 Phase 280 durable image insertion；成功后一次性加入一个 `ADD_ELEMENTS` undo action 并刷新画布。

## 原子性与失败语义

单张图继续拥有原版对齐的原子资产/事务/history。多图批次按输入顺序提交，但没有跨张数据库事务；任一张失败时
caller fail closed、显示 toast，已成功图片可通过既有 Undo 撤回。ADR-0261 明确记录该边界，不在 UI 层伪装
整批 rollback。

## 验证

- ArkTS 检查：新 caller 只有项目既有 warning；ingress/picker fixtures 与测试套件无诊断。
- 专项 Replay：
  - `D02_ORIGINAL_PHOTO_PICKER_CALLER_OK TOTAL=11 FAILED=0`
- 全量 Replay：
  - `REPLAY_FILES=268 FAILED=0`
- clean 后严格串行双 HAP：
  - clean：`BUILD SUCCESSFUL in 2 s 541 ms`
  - `note@ohosTest`：`BUILD SUCCESSFUL in 9 s 648 ms`
  - `note@default`：`BUILD SUCCESSFUL in 59 s 996 ms`
  - unsigned HAP：6,490,335 / 26,069,585 bytes
- `git diff --check` 通过；未启动模拟器、虚拟机、真机或 Hypium。

## 明确未闭环

- 真实设备 photo URI 权限和 provider 兼容性；
- HEIC、HEIF、TIFF、GIF、EXIF 变体与 WebP encoder 支持矩阵；
- 相机、Pasteboard、拖放等其他入口；
- 多图跨张事务性 rollback；
- 大批量内存/性能与端到端体验；
- Undo/Redo、重启、导入导出/同步的设备验收；
- `T-042` 继续保留为整个 Goal 最后一项。
