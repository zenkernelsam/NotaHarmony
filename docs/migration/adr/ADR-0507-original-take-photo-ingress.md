# ADR-0507：原版 Take Photo 拍照入库——cameraPicker 契约 + 共享照片管线复用

- 状态：已接受（2026-09-22，Phase 535）
- 背景：原版编辑器插入菜单（`qc.java`）在 Add Photo 与 Insert Math 之间
  有 "Take Photo" 项（`feature_note_toolbox__take_photo` +
  `ui_designsystem__camera_outline`，槽位 function3，`kkf.java:598`
  装配）。其实现 `f35.java:64` 构造 `IMAGE_CAPTURE` intent 并以
  `putExtra("output", uri)` + `addFlags(1|2)` 让系统相机把照片写进
  应用侧 URI，随后该 URI 走与 Add Photo 相同的统一入库管线。
  Harmony 此前只有相册选择/剪贴板两条图片入库入口，缺拍照入口。

## 决策

1. 新增 `OriginalCameraPickerCaller.ets`：`cameraPicker.pick(
   PickerMediaType.PHOTO, CAMERA_POSITION_BACK)` 取回系统相机产出 URI
   （PickerResult 直接给出 URI，与 EXTRA_OUTPUT "应用侧 URI 再入库"
   语义等价）；`resultCode !== 0 || resultUri === ''` → `''` → `[]`
   的取消静默返回契约与 `OriginalPhotoPickerCaller` 对齐；
   提供 `set/resetOriginalCameraUriCapturerForTest` 测试缝。
2. 不建独立拍照持久化旁路：URI 经 `isValidOriginalPhotoUri` 守卫后
   直接进 `importOriginalPhotos([uri], cacheDir)` —— 校验、字节上限、
   归一化与 Add Photo 完全同一管线（f35 "输出 URI 再入库"对应）。
3. 画布侧镜像既有照片入口：`@Prop @Watch cameraCaptureSignal` +
   `startOriginalCameraCapture()` 复用 `canStartOriginalPhotoInsert`
   生命周期门、`photoImportBusy` 忙标、`getOriginalPhotoInsertOrigin`
   原点捕获、`isPhotoContextCurrent` 过期页守卫、
   `commitOriginalPhotoInsert` 提交与部分失败 toast；
   `finally` 释放 `photoImportBusy` 并回调 `onPhotoIngressFinished`。
4. 页面侧 `NotePage.onTakePhoto` 与 `onInsertPhotos` 共用
   `photoImportLeaseActive` 租约：四条件互斥（photoImportLeaseActive /
   pageOperationBusy / historyPending / pageStructureLeaseActive）→
   置租约 → `cameraCaptureSignal++`。
5. `EditorToolbar` 完整栏在 Add Photo 与 Insert Math 之间加 Take Photo
   按钮，紧凑插入菜单同位插入（qc.java 菜单序）；`take_photo`
   双语资源沿用原版键位风格。

## 理由

- 原版 Take Photo 不是独立管线，而是"相机产出 URI → 统一照片入库"的
  前端变体（f35 只负责产出 URI）——Harmony 复用
  `importOriginalPhotos`/`commitOriginalPhotoInsert` 是对原版的忠实
  移植，自建旁路反而偏离。
- `cameraPicker.pick` 是 Harmony 对该场景的系统托管组件：相机由系统
  应用完成拍摄并返回 URI，与原版把拍摄委托给系统相机 intent 同构；
  无需 ohos.permission.CAMERA（原版同样无相机权限声明，依赖委托）。
- 租约语义按页级互斥而非仅照片互斥：拍照期间页操作/历史/结构操作
  必须同 Add Photo 一样被阻塞，故复用 `photoImportLeaseActive`
  而非新增独立锁。

## 后果

- 拍照路径天然获得既有全部边界行为：100MB 字节上限、扩展名/MIME
  校验、EXIF 归一化、锚点与页上下文守卫、逐图事务、部分失败 toast、
  持久历史元数据——无需重复实现。
- 函数落位：`startOriginalCameraCapture` 置于 `insertOriginalPhotos`
  与 `confirmMathInsert` 之间——四个既有 replay 按方法位置切片计数
  （isPhotoContextCurrent 出现次数等），新入口若落在
  `startOriginalPhotoInsert→startOriginalClipboardImagePaste` 区间会
  抬高计数；该位置同时保持主题聚集（照片入库族方法连续）。
- `d02-photo-import-page-operation-lease.mjs` 锚点合法扩展：
  `onPhotoIngressFinished` 计数 2→3、租约释放循环 +camera 入口。
- Replay `d02-original-take-photo-ingress.mjs` 27 项检查；
  全套 430/430；双 HAP 构建 0 错误。
